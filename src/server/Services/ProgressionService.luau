--!strict
-- ProgressionService: runs the story from MissionConfig, one step at a time.
--
-- Shared vs personal:
--   * The current mission/step and the world are SHARED by everyone in the server.
--   * Rewards are PERSONAL and saved: every player present when something happens gets
--     the checkpoint, realm, journal entry, or Doubt Token in their own profile.
--   * The first player to arrive sets the starting point from their save (the "host").
--     Others can replay content they already finished to help, with nothing lost.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
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
local BossAIService = require(script.Parent:WaitForChild("BossAIService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local MoonTipService = require(script.Parent:WaitForChild("MoonTipService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local ProgressionService = {}

-- Bosses by id. Stage D adds Orion, Scorpius, and Cetus behind the same interface.
local BOSSES: { [string]: { setCorrupted: () -> (), startEncounter: () -> (), restore: () -> () } } = {
	Leo = BossAIService,
}
local DEFAULT_PHASE_BY_KIND = {
	dialogue = "Dialogue",
	inspect = "Investigate",
	restore = "Confront",
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
	TweenService:Create(world.moon.glow, TweenInfo.new(3), { Transparency = glowTransparency }):Play()
	WorldStateService.setAttribute("MoonBrightness", brightness)
end

local function moonGlint()
	world.moon.glintEye.Transparency = 0
	task.delay(Tuning.Moon.GlintSeconds, function()
		world.moon.glintEye.Transparency = 1
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

local function bossForZone(zoneId: string)
	for _, mission in missions() do
		for _, step in mission.steps do
			if step.kind == "restore" and step.zoneId == zoneId then
				return BOSSES[step.bossId]
			end
		end
	end
	return nil
end

-- Marks a zone restored in the world (without rewards). Used live and when resuming.
local function markZoneRestored(zoneId: string)
	if WorldStateService.getAttribute(zoneId .. "Restored") then
		return
	end
	WorldStateService.setAttribute(zoneId .. "Restored", true)
	local realms = (WorldStateService.getAttribute("RestoredRealms") or 0) + 1
	WorldStateService.setAttribute("RestoredRealms", realms)
	setMoonBrightness(realms)
	local boss = bossForZone(zoneId)
	if boss then
		boss.restore()
	end
end

local advance: () -> ()

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
		WorldStateService.setAttribute("FixturesLocked", false)
		WorldStateService.setAttribute("MissionId", nil)
		WorldStateService.setPhase("FreeRoam", MissionConfig.FreeRoamObjectiveKey)
	end
end

local function restoreRealm(step: Step)
	local zoneId: string = step.zoneId
	markZoneRestored(zoneId)
	FixturePuzzleService.notifyAll("notice_restored")
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

	-- Checkpoint: everyone here can resume from this step later.
	local reached = stepIndex
	ProfileService.updateAll(function(profile)
		profile.checkpoints[mission.id] = math.max(profile.checkpoints[mission.id] or 0, reached)
	end)
	ProfileService.checkpointAll()
	for _, player in Players:GetPlayers() do
		MetricsService.log(player, "mission_step", reached)
	end

	if step.kind == "dialogue" then
		local seconds = DialogueService.playSequence(step.sequence)
		after(seconds + DIALOGUE_PADDING_SECONDS, advance)
	elseif step.kind == "inspect" then
		-- Continues from the onInspected listener.
	elseif step.kind == "restore" then
		if step.enterSequence then
			DialogueService.playSequence(step.enterSequence)
		end
		local boss = BOSSES[step.bossId]
		if boss then
			boss.startEncounter()
		end
		-- A team may already have fixed the lights while investigating.
		if DarknessMath.isRestored(zoneDef(step.zoneId), WorldStateService.getZoneSummary(step.zoneId)) then
			restoreRealm(step)
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

-- Builds the world for a starting point: earlier realms restored, then the step entered.
local function startAt(targetMission: number, targetStep: number)
	runId += 1
	MoonTipService.cancel()
	FixturePuzzleService.clearUndo()
	-- Baselines are the polluted "before" numbers, so capture them before restoring anything.
	for zoneId in FixtureConfig.Zones do
		WorldStateService.captureBaseline(zoneId)
		WorldStateService.setAttribute(zoneId .. "Restored", false)
	end
	WorldStateService.setAttribute("RestoredRealms", 0)
	for _, boss in BOSSES do
		boss.setCorrupted()
	end
	setMoonBrightness(0)

	local restoreZone = function(zoneId: string)
		WorldStateService.applyRestoredFixtures(zoneId)
		markZoneRestored(zoneId)
	end
	for index = 1, targetMission - 1 do
		local mission = missions()[index]
		for _, zoneId in mission and mission.zonesRestored or {} do
			restoreZone(zoneId)
		end
	end
	local mission = missions()[targetMission]
	if mission then
		for index = 1, targetStep - 1 do
			local step = mission.steps[index]
			if step.kind == "restore" then
				restoreZone(step.zoneId)
			end
		end
	end

	if mission == nil then
		-- Everything finished: free roam with every realm restored.
		missionIndex = targetMission
		stepIndex = 0
		WorldStateService.setAttribute("FixturesLocked", false)
		WorldStateService.setAttribute("MissionId", nil)
		WorldStateService.setPhase("FreeRoam", MissionConfig.FreeRoamObjectiveKey)
		return
	end
	missionIndex = targetMission
	stepIndex = targetStep - 1
	advance()
end

-- Picks where to start from the host's save: first unfinished mission, at its checkpoint.
local function startFromProfile(profile: ProfileSchema.Profile?)
	for index, mission in missions() do
		if not (profile and profile.completedMissions[mission.id]) then
			local checkpoint = if profile then profile.checkpoints[mission.id] else nil
			startAt(index, math.clamp(checkpoint or 1, 1, #mission.steps))
			return
		end
	end
	startAt(#missions() + 1, 1)
end

local function hintFor(speaker: string): string?
	local hints = (DialogueConfig.Hints :: any)[speaker]
	if hints == nil then
		return nil
	end
	return hints[WorldStateService.getPhase()] or hints.after
end

function ProgressionService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	showCompareEvent = remotes.ShowCompare

	FixturePuzzleService.onInspected(function(_player, fixtureId)
		local step = currentStep()
		if step and step.kind == "inspect" and WorldStateService.getZoneOfFixture(fixtureId) == step.zoneId then
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
			restoreRealm(step)
		end
	end)

	for speaker, prompt in world.npcPrompts do
		prompt.Triggered:Connect(function(player)
			local lineId = hintFor(speaker)
			if lineId then
				DialogueService.play({ lineId }, { player })
			end
		end)
	end
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

-- Developer world reset: polluted world, first mission, skipping its opening dialogue.
function ProgressionService.resetWorld()
	WorldStateService.resetAll()
	local mission = missions()[1]
	local firstStep = 1
	while mission.steps[firstStep] and mission.steps[firstStep].kind == "dialogue" do
		firstStep += 1
	end
	started = true
	startAt(1, math.min(firstStep, #mission.steps))
	FixturePuzzleService.notifyAll("notice_reset")
end

return ProgressionService
