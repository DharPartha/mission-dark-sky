--!strict
-- ProgressionService: runs the story from MissionConfig, one step at a time.
--
-- Shared vs personal:
--   * The current mission/step and the world are SHARED by everyone in the server.
--   * Rewards are PERSONAL and saved: every player present when something happens gets
--     the checkpoint, unlock, place restored, journal entry, or Doubt Token in their profile.
--     Players who join later get the tools the team already received (catch-up), so nobody
--     is locked out of progress.
--   * The first player to arrive sets the starting point from their save (the "host").
--     Others can replay content they already finished to help, with nothing lost.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local MissionConfig = require(ConfigFolder:WaitForChild("MissionConfig"))
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local ProfileSchema = require(SharedFolder:WaitForChild("ProfileSchema"))
local Types = require(SharedFolder:WaitForChild("Types"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local DialogueService = require(script.Parent:WaitForChild("DialogueService"))
local BossService = require(script.Parent:WaitForChild("BossService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local MoonTipService = require(script.Parent:WaitForChild("MoonTipService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))
local NavigationService = require(script.Parent:WaitForChild("NavigationService"))
local QuizService = require(script.Parent:WaitForChild("QuizService"))
local GuidanceService = require(script.Parent:WaitForChild("GuidanceService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local ProgressionService = {}

local DEFAULT_PHASE_BY_KIND = {
	dialogue = "Dialogue",
	quiz = "Quiz",
	interact = "Investigate",
	grant = "Dialogue",
	inspect = "Investigate",
	restore = "Confront",
	reach = "Ride",
	moonTip = "MoonTip",
}
-- Short pause after dialogue so the last bubble is readable before the next step.
local DIALOGUE_PADDING_SECONDS = 1
local HOST_PROFILE_TIMEOUT = 20

local world: WorldBuilder.World
local showCompareEvent: RemoteEvent
-- Bumped whenever the run restarts, so delayed steps from an older run do nothing.
local runId = 0
local missionIndex = 0
local stepIndex = 0
local started = false
-- Unlocks the team has received so far this session (given to late joiners).
local grantedSoFar: { [string]: boolean } = {}

type Step = { [string]: any }
type Mission = { id: string, steps: { Step }, zonesRestored: { string }? }

local function missions(): { Mission }
	return MissionConfig.Missions :: any
end

local function currentMission(): Mission?
	return missions()[missionIndex]
end

local function currentStep(): Step?
	local mission = currentMission()
	return if mission then mission.steps[stepIndex] else nil
end

local function zoneDef(zoneId: string): Types.ZoneDefinition
	return (FixtureConfig.Zones :: any)[zoneId]
end

local function after(seconds: number, action: () -> ())
	local myRun = runId
	task.delay(seconds, function()
		if runId == myRun then
			action()
		end
	end)
end

local function setMoonBrightness(realmsRestored: number)
	local brightness = Tuning.Moon.BaseBrightness + realmsRestored * Tuning.Moon.BrightnessPerRealm
	-- Brighter Moon = less transparent glow shell. Subtle on purpose (foreshadowing).
	local glowTransparency = math.clamp(0.9 - (brightness - 1) * 0.25, 0.45, 0.95)
	for _, moon in world.moons do
		TweenService:Create(moon.glow, TweenInfo.new(3), { Transparency = glowTransparency }):Play()
	end
	WorldStateService.setAttribute("MoonBrightness", brightness)
end

local function moonGlint()
	-- Foreshadowing: the red glint plus a chime with one wrong note (captioned, so it
	-- works with sound off).
	FixturePuzzleService.notifyAll("caption_moon_chime")
	for _, moon in world.moons do
		moon.glintEye.Transparency = 0
	end
	task.delay(Tuning.Moon.GlintSeconds, function()
		for _, moon in world.moons do
			moon.glintEye.Transparency = 1
		end
	end)
end

local function findTip(tipId: string): { [string]: any }?
	for _, tip in MoonTipsConfig.Tips do
		if tip.id == tipId then
			return tip :: any
		end
	end
	return nil
end

local function bossIdForZone(zoneId: string): string?
	for _, mission in missions() do
		for _, step in mission.steps do
			if step.kind == "restore" and step.zoneId == zoneId and step.bossId then
				return step.bossId
			end
		end
	end
	return nil
end

-- Marks a zone restored in the world (without rewards). Used live and when resuming.
-- Only boss realms count toward the Moon's growing brightness.
local function markZoneRestored(zoneId: string)
	if WorldStateService.getAttribute(zoneId .. "Restored") then
		return
	end
	WorldStateService.setAttribute(zoneId .. "Restored", true)
	local bossId = bossIdForZone(zoneId)
	if bossId then
		local realms = (WorldStateService.getAttribute("RestoredRealms") or 0) + 1
		WorldStateService.setAttribute("RestoredRealms", realms)
		setMoonBrightness(realms)
		BossService.restore(bossId)
		if WorldStateService.getAttribute("ActiveBoss") == bossId then
			WorldStateService.setAttribute("ActiveBoss", nil)
		end
	end
	-- The matching place in Byers Station improves too.
	WorldBuilder.setEchoesRestored(world, zoneId, true)
end

-- Records a Moon clue (MoonTipsConfig.Clues) in everyone's journal for Act III.
local function recordClue(clueId: string)
	if (MoonTipsConfig :: any).Clues == nil or (MoonTipsConfig :: any).Clues[clueId] == nil then
		return
	end
	ProfileService.updateAll(function(profile)
		ProfileSchema.addJournalEntry(profile, {
			id = "clue:" .. clueId,
			kind = "clue",
			key = clueId,
			at = os.time(),
			data = nil,
		})
	end)
end

local function grantUnlocks(unlocks: { string }, players: { Player }?)
	for _, unlock in unlocks do
		grantedSoFar[unlock] = true
	end
	local function give(profile: ProfileSchema.Profile, player: Player)
		for _, unlock in unlocks do
			if not profile.unlocks[unlock] then
				profile.unlocks[unlock] = true
				FixturePuzzleService.notify(player, "notice_unlocked_" .. unlock)
			end
		end
	end
	if players then
		for _, player in players do
			ProfileService.update(player, function(profile)
				give(profile, player)
			end)
		end
	else
		ProfileService.updateAll(give)
	end
	ProfileService.checkpointAll()
end

local function setActiveZone(zoneId: string?)
	if zoneId then
		WorldStateService.setAttribute("ActiveZone", zoneId)
	end
end

local advance: () -> ()

local function enterFreeRoam()
	WorldStateService.setAttribute("FixturesLocked", false)
	WorldStateService.setAttribute("MissionId", nil)
	WorldStateService.setAttribute("StepId", nil)
	WorldStateService.setPhase("FreeRoam", MissionConfig.FreeRoamObjectiveKey)
	GuidanceService.stepStarted("freeRoam", nil)
end

local function completeMission()
	local mission = currentMission()
	if mission == nil then
		return
	end
	ProfileService.updateAll(function(profile)
		profile.completedMissions[mission.id] = true
	end)
	ProfileService.checkpointAll()
	for _, player in Players:GetPlayers() do
		MetricsService.log(player, "mission_complete")
	end
	missionIndex += 1
	stepIndex = 0
	if missions()[missionIndex] then
		advance()
	else
		enterFreeRoam()
	end
end

local function restoreZone(step: Step)
	local zoneId: string = step.zoneId
	markZoneRestored(zoneId)
	GuidanceService.stepSolved()
	if step.bossId then
		recordClue("guardian_" .. zoneId)
		if (WorldStateService.getAttribute("RestoredRealms") or 0) >= 2 then
			recordClue("brighter")
			recordClue("red_glow")
		end
	end
	if step.bossId then
		FixturePuzzleService.notifyAll("notice_restored")
	else
		FixturePuzzleService.notifyAll("notice_zone_restored", zoneDef(zoneId).nameKey, "text")
	end
	showCompareEvent:FireAllClients()

	local before = WorldStateService.getAttribute(zoneId .. "BaseScore") or 0
	local afterScore = WorldStateService.getAttribute(zoneId .. "Score") or 0
	ProfileService.updateAll(function(profile)
		profile.restoredZones[zoneId] = true
		ProfileSchema.addJournalEntry(profile, {
			id = "realm:" .. zoneId,
			kind = "realm",
			key = zoneId,
			at = os.time(),
			data = { before = before, after = afterScore },
		})
	end)
	ProfileService.checkpointAll()
	for _, player in Players:GetPlayers() do
		MetricsService.log(player, "realm_restored", afterScore)
	end
	advance()
end

local function runMoonTip(step: Step)
	local tip = findTip(step.tipId)
	if tip == nil or not FeatureFlags.EnableMoonTips then
		advance()
		return
	end
	moonGlint()
	recordClue("chime")
	DialogueService.play({ tip.lineId })
	local myRun = runId
	MoonTipService.start(tip, function(outcome)
		if runId ~= myRun then
			return
		end
		ProfileService.updateAll(function(profile)
			if outcome.correct then
				profile.doubtTokens += 1
			end
			ProfileSchema.addJournalEntry(profile, {
				id = "moonTip:" .. tip.id,
				kind = "moonTip",
				key = tip.id,
				at = os.time(),
				data = { correct = outcome.correct, choice = outcome.choice },
			})
		end)
		ProfileService.checkpointAll()
		FixturePuzzleService.notifyAll(if outcome.correct then "notice_token" else "notice_no_token")
		for _, player in Players:GetPlayers() do
			MetricsService.log(player, if outcome.correct then "moon_tip_correct" else "moon_tip_incorrect")
		end
		local seconds = DialogueService.playSequence(outcome.sequence)
		after(seconds + DIALOGUE_PADDING_SECONDS, advance)
	end)
end

local function runQuiz(step: Step)
	local quizId: string = step.quizId
	QuizService.setActive(quizId)
	local myRun = runId
	local function finish()
		if runId == myRun and currentStep() == step then
			QuizService.setActive(nil)
			advance()
		end
	end
	if QuizService.everyoneAnswered(quizId) then
		-- Everyone here did this check before (returning players): skip it.
		finish()
		return
	end
	after(MissionConfig.QuizTimeoutSeconds, finish)
end

local function enterStep()
	local mission = currentMission()
	local step = currentStep()
	if mission == nil or step == nil then
		return
	end
	local phase = step.hintPhase or DEFAULT_PHASE_BY_KIND[step.kind] or "Dialogue"
	local objectiveArg = if step.kind == "restore" then zoneDef(step.zoneId).restoreThreshold else nil
	WorldStateService.setAttribute("MissionId", mission.id)
	WorldStateService.setAttribute("StepId", step.id)
	WorldStateService.setAttribute("FixturesLocked", step.locksFixtures == true)
	WorldStateService.setPhase(phase, step.objectiveKey, objectiveArg)
	setActiveZone(step.activeZone or step.zoneId)
	if step.companions then
		WorldBuilder.placeCompanions(world, step.companions)
	end
	if step.opensRift then
		NavigationService.setRiftOpen(true)
	end
	GuidanceService.stepStarted(step.kind, step.targetId)

	-- Checkpoint: everyone here can resume from this step later.
	local stepId: string = step.id
	ProfileService.updateAll(function(profile)
		profile.checkpoints[mission.id] = stepId
	end)
	ProfileService.checkpointAll()
	for _, player in Players:GetPlayers() do
		MetricsService.log(player, "mission_step", stepIndex)
	end

	if step.kind == "dialogue" then
		local seconds = DialogueService.playSequence(step.sequence)
		after(seconds + DIALOGUE_PADDING_SECONDS, advance)
	elseif step.kind == "grant" then
		grantUnlocks(step.unlocks)
		local seconds = if step.sequence then DialogueService.playSequence(step.sequence) else 0
		after(seconds + DIALOGUE_PADDING_SECONDS, advance)
	elseif step.kind == "quiz" then
		runQuiz(step)
	elseif step.kind == "reach" then
		NavigationService.setActiveTarget(step.targetId)
	elseif step.kind == "interact" or step.kind == "inspect" then
		-- Continues from the matching listener in init.
	elseif step.kind == "restore" then
		if step.enterSequence then
			DialogueService.playSequence(step.enterSequence)
		end
		if step.bossId then
			-- Bikes park inside an active guardian's arena (BikeService reads this).
			WorldStateService.setAttribute("ActiveBoss", step.bossId)
			BossService.startEncounter(step.bossId)
		end
		-- A team may already have fixed the lights while investigating.
		if DarknessMath.isRestored(zoneDef(step.zoneId), WorldStateService.getZoneSummary(step.zoneId)) then
			restoreZone(step)
		end
	elseif step.kind == "moonTip" then
		runMoonTip(step)
	end
end

advance = function()
	local mission = currentMission()
	if mission == nil then
		return
	end
	stepIndex += 1
	if stepIndex > #mission.steps then
		completeMission()
	else
		enterStep()
	end
end

-- Rebuilds the world for a starting point from the effects of every step before it:
-- restored zones, open Rift, granted tools, companion location, and Meter zone.
local function startAt(targetMission: number, targetStep: number)
	runId += 1
	MoonTipService.cancel()
	QuizService.setActive(nil)
	NavigationService.setActiveTarget(nil)
	NavigationService.setRiftOpen(false)
	FixturePuzzleService.clearUndo()
	table.clear(grantedSoFar)
	-- Baselines are the polluted "before" numbers, so capture them before restoring anything.
	for zoneId in FixtureConfig.Zones do
		WorldStateService.captureBaseline(zoneId)
		WorldStateService.setAttribute(zoneId .. "Restored", false)
	end
	WorldStateService.setAttribute("RestoredRealms", 0)
	BossService.setAllCorrupted()
	WorldStateService.setAttribute("ActiveBoss", nil)
	for zoneId in FixtureConfig.Zones do
		WorldBuilder.setEchoesRestored(world, zoneId, false)
	end
	setMoonBrightness(0)

	local companions = "hub"
	local activeZone: string? = nil
	for mIndex, mission in missions() do
		if mIndex > targetMission then
			break
		end
		local lastStep = if mIndex < targetMission then #mission.steps else targetStep - 1
		for sIndex = 1, lastStep do
			local step = mission.steps[sIndex]
			if step.kind == "restore" then
				WorldStateService.applyRestoredFixtures(step.zoneId)
				markZoneRestored(step.zoneId)
			elseif step.kind == "grant" then
				for _, unlock in step.unlocks do
					grantedSoFar[unlock] = true
				end
			end
			if step.opensRift then
				NavigationService.setRiftOpen(true)
			end
			companions = step.companions or companions
			activeZone = step.activeZone or step.zoneId or activeZone
		end
		if mIndex < targetMission then
			for _, zoneId in mission.zonesRestored or {} do
				WorldStateService.applyRestoredFixtures(zoneId)
				markZoneRestored(zoneId)
			end
		end
	end
	WorldBuilder.placeCompanions(world, companions)
	setActiveZone(activeZone or "Home")
	-- Everyone here gets the tools the story already handed out.
	local catchUp = {}
	for unlock in grantedSoFar do
		table.insert(catchUp, unlock)
	end
	if #catchUp > 0 then
		grantUnlocks(catchUp)
	end

	local mission = missions()[targetMission]
	if mission == nil then
		missionIndex = targetMission
		stepIndex = 0
		enterFreeRoam()
		return
	end
	missionIndex = targetMission
	stepIndex = targetStep - 1
	advance()
end

local function stepIndexById(mission: Mission, stepId: string?): number
	if stepId then
		for index, step in mission.steps do
			if step.id == stepId then
				return index
			end
		end
	end
	return 1
end

-- Picks where to start from the host's save: first unfinished mission, at its checkpoint.
local function startFromProfile(profile: ProfileSchema.Profile?)
	for index, mission in missions() do
		if not (profile and profile.completedMissions[mission.id]) then
			local checkpoint = if profile then profile.checkpoints[mission.id] else nil
			startAt(index, stepIndexById(mission, checkpoint))
			return
		end
	end
	startAt(#missions() + 1, 1)
end

function ProgressionService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	showCompareEvent = remotes.ShowCompare

	FixturePuzzleService.onInspected(function(_player, fixtureId)
		local step = currentStep()
		if step and step.kind == "inspect" and WorldStateService.getZoneOfFixture(fixtureId) == step.zoneId then
			GuidanceService.stepSolved()
			advance()
		end
	end)

	FixturePuzzleService.onEvidence(function(evidenceKey)
		ProfileService.updateAll(function(profile)
			ProfileSchema.addJournalEntry(profile, {
				id = "evidence:" .. evidenceKey,
				kind = "evidence",
				key = evidenceKey,
				at = os.time(),
				data = nil,
			})
		end)
	end)

	WorldStateService.onZoneChanged(function(zoneId: string, summary: Types.ZoneSummary)
		local step = currentStep()
		if step == nil or step.kind ~= "restore" or step.zoneId ~= zoneId then
			return
		end
		if DarknessMath.isRestored(zoneDef(zoneId), summary) then
			restoreZone(step)
		end
	end)

	for targetId, prompt in world.interactables do
		prompt.Triggered:Connect(function()
			local step = currentStep()
			if step and step.kind == "interact" and step.targetId == targetId then
				GuidanceService.stepSolved()
				advance()
			end
		end)
	end

	NavigationService.onReached(function(targetId)
		local step = currentStep()
		if step and step.kind == "reach" and step.targetId == targetId then
			advance()
		end
	end)

	QuizService.onAnswered(function(_player, quizId)
		local step = currentStep()
		if step and step.kind == "quiz" and step.quizId == quizId and QuizService.everyoneAnswered(quizId) then
			QuizService.setActive(nil)
			advance()
		end
	end)

	-- Late joiners get the tools the team already has, so they can take part right away.
	ProfileService.onLoaded(function(player)
		if not started then
			return
		end
		local unlocks = {}
		for unlock in grantedSoFar do
			table.insert(unlocks, unlock)
		end
		if #unlocks > 0 then
			grantUnlocks(unlocks, { player })
		end
	end)
end

-- Called when the first client is ready; the host's save picks the starting point.
function ProgressionService.startForHost(host: Player)
	if started then
		return
	end
	started = true
	local profile = ProfileService.waitForProfile(host, HOST_PROFILE_TIMEOUT)
	startFromProfile(profile)
end

-- Developer world reset: polluted world, first mission, skipping its opening quiz and
-- dialogue steps so testers reach gameplay quickly.
function ProgressionService.resetWorld()
	WorldStateService.resetAll()
	local mission = missions()[1]
	local firstStep = 1
	while mission.steps[firstStep] and (mission.steps[firstStep].kind == "dialogue" or mission.steps[firstStep].kind == "quiz") do
		firstStep += 1
	end
	started = true
	startAt(1, math.min(firstStep, #mission.steps))
	FixturePuzzleService.notifyAll("notice_reset")
end

-- Developer shortcut: start a mission by id (used by the "jump to" test tool).
function ProgressionService.jumpToMission(missionId: string): boolean
	for index, mission in missions() do
		if mission.id == missionId then
			WorldStateService.resetAll()
			started = true
			startAt(index, 1)
			return true
		end
	end
	return false
end

return ProgressionService
