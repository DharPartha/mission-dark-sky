--!strict
-- NavigationService: moving between places safely.
--   * Checkpoints: walking near one sets your personal "Get unstuck" return point.
--   * Get unstuck: returns you to your last checkpoint (works on foot or on a bike).
--   * Reach targets: tells ProgressionService when anyone reaches a story location.
--   * The Rift: covered bridge <-> Glarelands. The town side opens through the story;
--     the Glarelands side is always open so nobody is stranded.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local NavigationService = {}

local POLL_SECONDS = 0.5

local world: WorldBuilder.World
local lastCheckpoint: { [Player]: string } = {}
local activeTarget: string? = nil
local reachedListeners: { (targetId: string, player: Player) -> () } = {}
local beforeTeleportListeners: { (player: Player) -> () } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return if rootPart and rootPart:IsA("BasePart") then rootPart else nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function NavigationService.regionOf(position: Vector3): string
	local glare = WorldConfig.Regions.Glarelands
	if position.X >= glare.minX and position.X <= glare.maxX then
		return "Glarelands"
	end
	return "Town"
end

-- Moves a player's character, after letting other services (bikes) prepare.
function NavigationService.teleport(player: Player, position: Vector3)
	local rootPart = rootOf(player)
	if rootPart == nil then
		return
	end
	for _, callback in beforeTeleportListeners do
		callback(player)
	end
	-- Make sure the destination is loaded for this player when streaming is on.
	pcall(function()
		player:RequestStreamAroundAsync(position, 5)
	end)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	end
end

function NavigationService.teleportAll(position: Vector3)
	for index, player in Players:GetPlayers() do
		-- Spread players out a little so nobody lands inside a teammate.
		local offset = Vector3.new(((index - 1) % 4) * 4 - 6, 0, math.floor((index - 1) / 4) * 4)
		task.spawn(NavigationService.teleport, player, position + offset)
	end
end

function NavigationService.setRiftOpen(open: boolean)
	WorldStateService.setAttribute("RiftOpen", open)
	local rift = world.rifts.town
	rift.part.Transparency = if open then 0.15 else 1
	rift.prompt.Enabled = open
	local glow = rift.part:FindFirstChildOfClass("PointLight")
	if glow then
		glow.Enabled = open
	end
end

-- The story step that waits for someone to reach a place sets this (nil = none).
function NavigationService.setActiveTarget(targetId: string?)
	activeTarget = targetId
	WorldStateService.setAttribute("ReachTarget", targetId)
end

function NavigationService.onReached(callback: (targetId: string, player: Player) -> ())
	table.insert(reachedListeners, callback)
end

function NavigationService.onBeforeTeleport(callback: (player: Player) -> ())
	table.insert(beforeTeleportListeners, callback)
end

local function poll()
	for _, player in Players:GetPlayers() do
		local rootPart = rootOf(player)
		if rootPart then
			local position = rootPart.Position
			for checkpointId, checkpoint in WorldConfig.Checkpoints do
				if flatDistance(position, checkpoint) <= WorldConfig.CheckpointRadius then
					lastCheckpoint[player] = checkpointId
				end
			end
			local target = activeTarget
			if target then
				local trigger = (WorldConfig.Triggers :: any)[target]
				if trigger and flatDistance(position, trigger.position) <= trigger.radius then
					activeTarget = nil
					WorldStateService.setAttribute("ReachTarget", nil)
					for _, callback in reachedListeners do
						task.spawn(callback, target, player)
					end
				end
			end
		end
	end
end

function NavigationService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	NavigationService.setRiftOpen(false)

	world.rifts.town.prompt.Triggered:Connect(function(player)
		if WorldStateService.getAttribute("RiftOpen") ~= true then
			FixturePuzzleService.notify(player, "notice_rift_closed")
			return
		end
		NavigationService.teleport(player, WorldConfig.Glarelands.Arrival)
		lastCheckpoint[player] = "glare_arrival"
	end)
	world.rifts.glare.prompt.Triggered:Connect(function(player)
		NavigationService.teleport(player, WorldConfig.Checkpoints.bridge)
		lastCheckpoint[player] = "bridge"
	end)

	RemoteGuard.connect(remotes.Unstuck, "Unstuck", function(player: Player)
		local checkpointId = lastCheckpoint[player] or "hub"
		local position = (WorldConfig.Checkpoints :: any)[checkpointId] or WorldConfig.Town.Spawn
		NavigationService.teleport(player, position)
		FixturePuzzleService.notify(player, "notice_unstuck")
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastCheckpoint[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= POLL_SECONDS then
			elapsed = 0
			poll()
		end
	end)
end

return NavigationService
