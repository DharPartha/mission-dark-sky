--!strict
-- QuestService: the Leo vertical-slice state machine and the Moon's "Doubt it!" tip.
--
--   Intro ──(intro dialogue ends)──> Investigate ──(first Inspect)──> Confront
--   Confront ──(score >= threshold and safe paths lit)──> Restored
--   Restored ──(restored dialogue ends)──> MoonTip ──(team vote resolves)──> Complete
--
-- The server owns every transition. Co-op: all players share one quest; the Moon tip is
-- a team vote with preset buttons (no chat needed). Solo play is a team of one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local Types = require(SharedFolder:WaitForChild("Types"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))

local GameStateService = require(script.Parent:WaitForChild("GameStateService"))
local DialogueService = require(script.Parent:WaitForChild("DialogueService"))
local BossAIService = require(script.Parent:WaitForChild("BossAIService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local QuestService = {}

local ZONE_ID = BossConfig.Leo.zoneId
-- Short pause after dialogue so the last bubble is readable before the next step.
local DIALOGUE_PADDING_SECONDS = 1

local world: WorldBuilder.World
local showCompareEvent: RemoteEvent
-- Bumped on reset so pending delayed steps from an older run do nothing.
local runId = 0
local activeTip: { [string]: any }? = nil
local votes: { [Player]: string } = {}

local function after(seconds: number, step: () -> ())
	local myRun = runId
	task.delay(seconds, function()
		if runId == myRun then
			step()
		end
	end)
end

local function setMoonBrightness(realmsRestored: number)
	local brightness = Tuning.Moon.BaseBrightness + realmsRestored * Tuning.Moon.BrightnessPerRealm
	-- Brighter Moon = less transparent glow shell. Subtle on purpose.
	local glowTransparency = math.clamp(0.9 - (brightness - 1) * 0.25, 0.45, 0.95)
	TweenService:Create(world.moon.glow, TweenInfo.new(3), { Transparency = glowTransparency }):Play()
	GameStateService.setAttribute("MoonBrightness", brightness)
end

local function moonGlint()
	world.moon.glintEye.Transparency = 0
	task.delay(Tuning.Moon.GlintSeconds, function()
		world.moon.glintEye.Transparency = 1
	end)
end

local function findTip(trigger: string): { [string]: any }?
	for _, tip in MoonTipsConfig.Tips do
		if tip.trigger == trigger then
			return tip :: any
		end
	end
	return nil
end

local function complete()
	GameStateService.setPhase("Complete", "objective_complete", GameStateService.getAttribute("DoubtTokens") or 0)
	DialogueService.playSequence("complete")
end

local function resolveVote()
	local tip = activeTip
	if tip == nil or GameStateService.getPhase() ~= "MoonTip" then
		return
	end
	activeTip = nil

	local doubt, agree = 0, 0
	for _, choice in votes do
		if choice == "doubt" then
			doubt += 1
		else
			agree += 1
		end
	end
	table.clear(votes)
	GameStateService.setAttribute("VoteTipId", nil)

	local sequence: string
	local correct = false
	if doubt == agree then
		-- In character: the Moon pushes her own answer when the team cannot decide.
		sequence = tip.onTie
	elseif doubt > agree then
		sequence = tip.onDoubt
		correct = tip.isMisleading
	else
		sequence = tip.onAgree
		correct = not tip.isMisleading
	end

	if correct then
		GameStateService.addDoubtToken()
		GameStateService.addJournalEntry({
			kind = "moonTip",
			tipId = tip.id,
			evidenceKey = tip.evidenceKey,
			choice = if doubt > agree then "doubt" else "agree",
		})
		FixturePuzzleService.notifyAll("notice_token")
	else
		FixturePuzzleService.notifyAll("notice_no_token")
	end
	GameStateService.setAttribute("LastTipCorrect", correct)

	local seconds = DialogueService.playSequence(sequence)
	after(seconds + DIALOGUE_PADDING_SECONDS, complete)
end

local function updateVoteCount()
	local cast = 0
	for player in votes do
		if player.Parent == Players then
			cast += 1
		end
	end
	GameStateService.setAttribute("VotesCast", cast)
	GameStateService.setAttribute("VotersNeeded", #Players:GetPlayers())
	if cast >= #Players:GetPlayers() then
		resolveVote()
	end
end

local function startMoonTip()
	local tip = if FeatureFlags.EnableMoonTips then findTip("afterRealm:" .. ZONE_ID) else nil
	if tip == nil then
		complete()
		return
	end
	activeTip = tip
	table.clear(votes)
	GameStateService.setPhase("MoonTip", "objective_moontip")
	GameStateService.setAttribute("VoteTipId", tip.id)
	GameStateService.setAttribute("VoteDeadline", Workspace:GetServerTimeNow() + Tuning.Moon.VoteTimeoutSeconds)
	updateVoteCount()
	moonGlint()
	DialogueService.play({ tip.lineId })
	after(Tuning.Moon.VoteTimeoutSeconds, resolveVote)
end

local function restoreRealm()
	GameStateService.setPhase("Restored", "objective_restored")
	BossAIService.restore()
	local realms = (GameStateService.getAttribute("RestoredRealms") or 0) + 1
	GameStateService.setAttribute("RestoredRealms", realms)
	GameStateService.setAttribute(ZONE_ID .. "Restored", true)
	setMoonBrightness(realms)
	FixturePuzzleService.notifyAll("notice_restored")
	showCompareEvent:FireAllClients()
	GameStateService.addJournalEntry({
		kind = "realm",
		zoneId = ZONE_ID,
		before = GameStateService.getAttribute(ZONE_ID .. "BaseScore"),
		after = GameStateService.getAttribute(ZONE_ID .. "Score"),
	})
	local seconds = DialogueService.playSequence(BossConfig.Leo.restoredSequence)
	after(seconds + DIALOGUE_PADDING_SECONDS, startMoonTip)
end

local function startConfront()
	local zone = (FixtureConfig.Zones :: any)[ZONE_ID]
	GameStateService.setPhase("Confront", "objective_confront", zone.restoreThreshold)
	DialogueService.playSequence(BossConfig.Leo.wakeSequence)
	BossAIService.startEncounter()
	-- A team may already have fixed lights while investigating.
	local summary = GameStateService.getZoneSummary(ZONE_ID)
	if DarknessMath.isRestored(zone, summary) then
		restoreRealm()
	end
end

local function hintFor(speaker: string): string?
	local hints = (DialogueConfig.Hints :: any)[speaker]
	if hints == nil then
		return nil
	end
	return hints[GameStateService.getPhase()] or hints.after
end

function QuestService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	showCompareEvent = remotes.ShowCompare

	FixturePuzzleService.onInspected(function()
		if GameStateService.getPhase() == "Investigate" then
			startConfront()
		end
	end)

	GameStateService.onZoneChanged(function(zoneId: string, summary: Types.ZoneSummary)
		if zoneId ~= ZONE_ID or GameStateService.getPhase() ~= "Confront" then
			return
		end
		if DarknessMath.isRestored((FixtureConfig.Zones :: any)[ZONE_ID], summary) then
			restoreRealm()
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

	remotes.MoonVote.OnServerEvent:Connect(function(player: Player, choice: unknown)
		if GameStateService.getPhase() ~= "MoonTip" or activeTip == nil then
			return
		end
		if choice ~= "doubt" and choice ~= "agree" then
			return
		end
		-- Players may change their vote until the vote resolves.
		votes[player] = choice :: string
		updateVoteCount()
	end)

	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		if activeTip then
			-- Defer so the leaving player is no longer counted.
			task.defer(updateVoteCount)
		end
	end)
end

function QuestService.start()
	runId += 1
	activeTip = nil
	table.clear(votes)
	BossAIService.setCorrupted()
	setMoonBrightness(0)
	GameStateService.captureBaseline(ZONE_ID)
	GameStateService.setAttribute(ZONE_ID .. "Restored", false)
	GameStateService.setPhase("Intro", "objective_intro")
	local seconds = DialogueService.playSequence("intro")
	after(seconds + DIALOGUE_PADDING_SECONDS, function()
		GameStateService.setPhase("Investigate", "objective_investigate")
	end)
end

-- Studio test reset: polluted fixtures, Leo corrupted, straight to Investigate.
function QuestService.resetForTesting()
	runId += 1
	activeTip = nil
	table.clear(votes)
	GameStateService.setAttribute("VoteTipId", nil)
	FixturePuzzleService.clearUndo()
	GameStateService.resetAll()
	BossAIService.setCorrupted()
	setMoonBrightness(0)
	GameStateService.captureBaseline(ZONE_ID)
	GameStateService.setAttribute(ZONE_ID .. "Restored", false)
	GameStateService.setPhase("Investigate", "objective_investigate")
	FixturePuzzleService.notifyAll("notice_reset")
end

return QuestService
