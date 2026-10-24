--!strict
-- GuidanceService: adaptive hints so nobody is hard-locked, without solving puzzles for them.
--   * Talk to a friend or press Hint any time: a hint for the current step.
--   * If a step takes a while, a friend offers a hint automatically. Players who solved
--     earlier puzzles without automatic hints ("skill") get them later next time.
--   * Reach steps also show a guide beam over the destination after a while.
-- Hints point at what to look at or which principle to try; they never perform actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local DialogueService = require(script.Parent:WaitForChild("DialogueService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local GuidanceService = {}

local FRIENDS = { "Aadi", "Aditya", "Adrika" }
-- Step kinds where players are working something out (dialogue steps need no hints).
local HINTABLE = { quiz = true, interact = true, inspect = true, restore = true, reach = true }
local CHECK_SECONDS = 2

local stepStartedAt = os.clock()
local stepKind: string? = nil
local stepTarget: string? = nil
local autoHinted: { [Player]: boolean } = {}
local friendIndex = 0

function GuidanceService.hintFor(speaker: string): string?
	local hints = (DialogueConfig.Hints :: any)[speaker]
	if hints == nil then
		return nil
	end
	return hints[WorldStateService.getPhase()] or hints.after
end

local function sendHint(player: Player)
	friendIndex = (friendIndex % #FRIENDS) + 1
	local lineId = GuidanceService.hintFor(FRIENDS[friendIndex])
	if lineId then
		DialogueService.play({ lineId }, { player })
	end
end

local function skillOf(player: Player): number
	local profile = ProfileService.getProfile(player)
	return if profile then math.min(profile.stats.skill or 0, Tuning.Guidance.MaxSkillLevel) else 0
end

-- Called by ProgressionService whenever a new step begins.
function GuidanceService.stepStarted(kind: string, targetId: string?)
	stepStartedAt = os.clock()
	stepKind = kind
	stepTarget = targetId
	table.clear(autoHinted)
	WorldStateService.setAttribute("BeaconTarget", nil)
end

-- Called when a puzzle step is solved: players who needed no automatic hint gain skill.
function GuidanceService.stepSolved()
	ProfileService.updateAll(function(profile, player)
		if not autoHinted[player] then
			profile.stats.skill = math.min((profile.stats.skill or 0) + 1, Tuning.Guidance.MaxSkillLevel)
		end
	end)
end

local function check()
	if not FeatureFlags.EnableAutoHints or stepKind == nil or not HINTABLE[stepKind] then
		return
	end
	local elapsed = os.clock() - stepStartedAt
	for _, player in Players:GetPlayers() do
		local delay = Tuning.Guidance.AutoHintBaseSeconds + skillOf(player) * Tuning.Guidance.AutoHintPerSkillSeconds
		if not autoHinted[player] and elapsed >= delay then
			autoHinted[player] = true
			sendHint(player)
			MetricsService.log(player, "auto_hint_shown", math.floor(elapsed))
		end
	end
	if stepKind == "reach" and stepTarget and elapsed >= Tuning.Guidance.BeaconAfterSeconds then
		WorldStateService.setAttribute("BeaconTarget", stepTarget)
	end
end

function GuidanceService.init(world: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	for speaker, prompt in world.npcPrompts do
		prompt.Triggered:Connect(function(player)
			local lineId = GuidanceService.hintFor(speaker)
			if lineId then
				DialogueService.play({ lineId }, { player })
			end
		end)
	end

	RemoteGuard.connect(remotes.RequestHint, "RequestHint", function(player: Player)
		sendHint(player)
		MetricsService.log(player, "hint_requested")
		if stepKind == "reach" and stepTarget then
			WorldStateService.setAttribute("BeaconTarget", stepTarget)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		autoHinted[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			check()
		end
	end)
end

return GuidanceService
