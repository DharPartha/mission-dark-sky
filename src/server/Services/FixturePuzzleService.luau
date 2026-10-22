--!strict
-- FixturePuzzleService: handles Inspect prompts and fixture actions from players.
--
-- Every request is validated on the server before anything changes:
--   1. argument types and lengths      4. per-player cooldown
--   2. fixture and verb/option exist    5. quest phase allows changes
--   3. player is alive and close enough 6. FixtureRules safety rules (in shared code)
-- Rejected requests get a readable Notice explaining why. Clients never write state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local Types = require(SharedFolder:WaitForChild("Types"))
local FixtureRules = require(SharedFolder:WaitForChild("FixtureRules"))

local GameStateService = require(script.Parent:WaitForChild("GameStateService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local FixturePuzzleService = {}

local MAX_ARGUMENT_LENGTH = 40

local world: WorldBuilder.World
local noticeEvent: RemoteEvent
local openMenuEvent: RemoteEvent
local lastActionAt: { [Player]: number } = {}
local undoStacks: { [string]: { Types.FixtureState } } = {}
local inspectListeners: { (player: Player, fixtureId: string) -> () } = {}

local function notify(player: Player, key: string, arg: (string | number)?, argKind: string?)
	noticeEvent:FireClient(player, key, arg, argKind)
end

-- Evidence is team knowledge in co-op, so everyone hears about new finds.
local function recordEvidence(evidenceKey: string?)
	if evidenceKey and GameStateService.addEvidence(evidenceKey) then
		for _, other in Players:GetPlayers() do
			notify(other, "notice_evidence", evidenceKey, "evidence")
		end
	end
end

local function isNear(player: Player, parts: WorldBuilder.FixtureParts): boolean
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if rootPart == nil or not rootPart:IsA("BasePart") or humanoid == nil or humanoid.Health <= 0 then
		return false
	end
	local offset = rootPart.Position - parts.anchor.Position
	-- Horizontal distance only, so jumping does not matter.
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Tuning.Interact.MaxActionDistance
end

local function phaseAllowsChanges(): boolean
	return GameStateService.getPhase() ~= "Intro"
end

local function pushUndo(fixtureId: string, previous: Types.FixtureState)
	local stack = undoStacks[fixtureId]
	if stack == nil then
		stack = {}
		undoStacks[fixtureId] = stack
	end
	table.insert(stack, previous)
	if #stack > Tuning.Interact.UndoDepth then
		table.remove(stack, 1)
	end
end

local function handleAction(player: Player, fixtureId: unknown, verb: unknown, option: unknown)
	if typeof(fixtureId) ~= "string" or typeof(verb) ~= "string" or typeof(option) ~= "string" then
		return
	end
	if #fixtureId > MAX_ARGUMENT_LENGTH or #verb > MAX_ARGUMENT_LENGTH or #option > MAX_ARGUMENT_LENGTH then
		return
	end
	local parts = world.fixtures[fixtureId]
	local def = GameStateService.getDefinition(fixtureId)
	local state = GameStateService.getFixtureState(fixtureId)
	if parts == nil or def == nil or state == nil then
		notify(player, "notice_bad_request")
		return
	end
	if verb ~= "UNDO" and FixtureRules.VerbOptions[verb] == nil then
		notify(player, "notice_bad_request")
		return
	end

	local now = os.clock()
	if now - (lastActionAt[player] or 0) < Tuning.Interact.ActionCooldownSeconds then
		notify(player, "notice_cooldown")
		return
	end
	lastActionAt[player] = now

	if not isNear(player, parts) then
		notify(player, "notice_too_far")
		return
	end
	if not phaseAllowsChanges() then
		notify(player, "notice_wait_intro")
		return
	end

	if verb == "UNDO" then
		local stack = undoStacks[fixtureId]
		local previous = if stack then table.remove(stack) else nil
		if previous == nil then
			notify(player, "notice_nothing_to_undo")
			return
		end
		GameStateService.setFixtureState(fixtureId, previous)
		notify(player, "notice_undo")
		return
	end

	local result = FixtureRules.apply(def, state, verb, option)
	if verb == "QUESTION" then
		GameStateService.markQuestioned(fixtureId)
	end
	recordEvidence(result.evidenceKey)

	local argKind = if typeof(result.noticeArg) == "string" then "text" else nil
	notify(player, result.noticeKey, result.noticeArg, argKind)
	if not result.ok then
		return
	end
	-- QUESTION "ask" changes nothing, so it does not need an undo step.
	if not (verb == "QUESTION" and option == "ask") then
		pushUndo(fixtureId, state)
		GameStateService.setFixtureState(fixtureId, result.state)
	end
end

local function handleInspect(player: Player, fixtureId: string)
	if not phaseAllowsChanges() then
		notify(player, "notice_wait_intro")
		return
	end
	recordEvidence("glare_reading")
	openMenuEvent:FireClient(player, fixtureId)
	for _, callback in inspectListeners do
		task.spawn(callback, player, fixtureId)
	end
end

function FixturePuzzleService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	noticeEvent = remotes.Notice
	openMenuEvent = remotes.OpenFixtureMenu

	for fixtureId, parts in world.fixtures do
		parts.prompt.Triggered:Connect(function(player)
			handleInspect(player, fixtureId)
		end)
	end

	remotes.FixtureAction.OnServerEvent:Connect(handleAction)

	-- Keep the world in sync with state, whoever changed it (actions, undo, reset).
	GameStateService.onFixtureChanged(function(fixtureId, state)
		local parts = world.fixtures[fixtureId]
		if parts then
			WorldBuilder.applyFixtureVisual(parts, state)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastActionAt[player] = nil
	end)
end

function FixturePuzzleService.onInspected(callback: (player: Player, fixtureId: string) -> ())
	table.insert(inspectListeners, callback)
end

function FixturePuzzleService.clearUndo()
	table.clear(undoStacks)
end

function FixturePuzzleService.notify(player: Player, key: string, arg: (string | number)?, argKind: string?)
	notify(player, key, arg, argKind)
end

function FixturePuzzleService.notifyAll(key: string, arg: (string | number)?, argKind: string?)
	for _, player in Players:GetPlayers() do
		notify(player, key, arg, argKind)
	end
end

return FixturePuzzleService
