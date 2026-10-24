--!strict
-- BikeService: bicycle ride mode. A bike model is welded to the rider and the server sets
-- the ride speed. There is no free-rolling physics, so a bike cannot flip or get stuck;
-- "Get unstuck" still works if a player wedges themselves somewhere.
--
-- Server rules: you need the bike unlock; no riding near puzzle fixtures (auto-dismount);
-- boost and bell have cooldowns; dismount before any teleport; a speed sanity check pulls
-- back anyone moving impossibly fast (for example an exploit), with a grace period after
-- legitimate teleports.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local NavigationService = require(script.Parent:WaitForChild("NavigationService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BikeModel = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("BikeModel"))

local BikeService = {}

local POLL_SECONDS = 0.5
local BELL_HEAR_DISTANCE = 90
local FRAME_COLORS = { Color3.fromRGB(60, 120, 200), Color3.fromRGB(200, 80, 60), Color3.fromRGB(70, 160, 90), Color3.fromRGB(200, 160, 50) }

type Rider = {
	model: Model,
	boostReadyAt: number,
	bellReadyAt: number,
	boosting: number, -- token so an old boost cannot end a newer one
	savedJumpPower: number,
	savedUseJumpPower: boolean,
}

local world: WorldBuilder.World
local bellEvent: RemoteEvent
local riders: { [Player]: Rider } = {}
local lastPositions: { [Player]: Vector3 } = {}
local strikes: { [Player]: number } = {}
local graceUntil: { [Player]: number } = {}

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and rootPart and rootPart:IsA("BasePart") then
		return humanoid, rootPart
	end
	return nil, nil
end

local function nearFixture(position: Vector3): boolean
	for _, parts in world.fixtures do
		local anchor = parts.anchor.Position
		if Vector3.new(position.X - anchor.X, 0, position.Z - anchor.Z).Magnitude <= Tuning.Bike.NoRideRadius then
			return true
		end
	end
	return false
end

function BikeService.dismount(player: Player)
	local rider = riders[player]
	if rider == nil then
		return
	end
	riders[player] = nil
	rider.model:Destroy()
	player:SetAttribute("Riding", false)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = Tuning.Glare.NormalWalkSpeed
		humanoid.UseJumpPower = rider.savedUseJumpPower
		humanoid.JumpPower = rider.savedJumpPower
	end
end

local function mount(player: Player)
	if not FeatureFlags.EnableBikes or riders[player] then
		return
	end
	if not ProfileService.hasUnlock(player, "bike") then
		FixturePuzzleService.notify(player, "notice_bike_locked")
		return
	end
	local humanoid, rootPart = humanoidOf(player)
	if humanoid == nil or rootPart == nil then
		return
	end
	if nearFixture(rootPart.Position) then
		FixturePuzzleService.notify(player, "notice_bike_no_ride")
		return
	end

	local model = BikeModel.create(FRAME_COLORS[(player.UserId % #FRAME_COLORS) + 1])
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local offset = part:GetAttribute("BikeOffset")
			part.CFrame = rootPart.CFrame * (if typeof(offset) == "CFrame" then offset else CFrame.identity)
			local weld = Instance.new("Weld")
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.C0 = if typeof(offset) == "CFrame" then offset else CFrame.identity
			weld.Parent = part
		end
	end
	model.Parent = player.Character

	riders[player] = {
		model = model,
		boostReadyAt = 0,
		bellReadyAt = 0,
		boosting = 0,
		savedJumpPower = humanoid.JumpPower,
		savedUseJumpPower = humanoid.UseJumpPower,
	}
	-- Space is the brake while riding, so jumping is off.
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = Tuning.Bike.RideSpeed
	player:SetAttribute("Riding", true)
end

local function boost(player: Player)
	local rider = riders[player]
	local humanoid = humanoidOf(player)
	local now = os.clock()
	if rider == nil or humanoid == nil or now < rider.boostReadyAt then
		return
	end
	rider.boostReadyAt = now + Tuning.Bike.BoostCooldownSeconds
	rider.boosting += 1
	local token = rider.boosting
	humanoid.WalkSpeed = Tuning.Bike.BoostSpeed
	player:SetAttribute("BoostReadyAt", workspace:GetServerTimeNow() + Tuning.Bike.BoostCooldownSeconds)
	task.delay(Tuning.Bike.BoostSeconds, function()
		if riders[player] == rider and rider.boosting == token and humanoid.Parent then
			humanoid.WalkSpeed = Tuning.Bike.RideSpeed
		end
	end)
end

local function bell(player: Player)
	local rider = riders[player]
	local _, rootPart = humanoidOf(player)
	local now = os.clock()
	if rider == nil or rootPart == nil or now < rider.bellReadyAt then
		return
	end
	rider.bellReadyAt = now + Tuning.Bike.BellCooldownSeconds
	-- Sound is optional (AudioConfig later); every client near enough gets a caption.
	for _, other in Players:GetPlayers() do
		local _, otherRoot = humanoidOf(other)
		if otherRoot and (otherRoot.Position - rootPart.Position).Magnitude <= BELL_HEAR_DISTANCE then
			bellEvent:FireClient(other, rootPart.Position)
		end
	end
end

local function poll()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local _, rootPart = humanoidOf(player)
		if rootPart then
			local position = rootPart.Position
			if riders[player] and nearFixture(position) then
				BikeService.dismount(player)
				FixturePuzzleService.notify(player, "notice_bike_parked")
			end
			-- Speed sanity check (ignores vertical falls and teleports).
			local last = lastPositions[player]
			if last and now >= (graceUntil[player] or 0) then
				local speed = Vector3.new(position.X - last.X, 0, position.Z - last.Z).Magnitude / POLL_SECONDS
				if speed > Tuning.Bike.MaxPlausibleSpeed then
					strikes[player] = (strikes[player] or 0) + 1
					if strikes[player] >= 3 then
						strikes[player] = 0
						warn(string.format("[DarkSky] Implausible speed for user %d (%.0f studs/s); pulled back", player.UserId, speed))
						rootPart.CFrame = CFrame.new(last + Vector3.new(0, 1, 0))
						position = last
					end
				else
					strikes[player] = 0
				end
			end
			lastPositions[player] = position
		end
	end
end

function BikeService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	bellEvent = remotes.BellRang

	RemoteGuard.connect(remotes.BikeRequest, "BikeRequest", function(player: Player, action: any)
		if action == "toggle" then
			if riders[player] then
				BikeService.dismount(player)
			else
				mount(player)
			end
		elseif action == "boost" then
			boost(player)
		elseif action == "bell" then
			bell(player)
		end
	end)

	NavigationService.onBeforeTeleport(function(player)
		BikeService.dismount(player)
		graceUntil[player] = os.clock() + 3
		lastPositions[player] = nil
	end)

	local function onCharacter(player: Player)
		riders[player] = nil
		player:SetAttribute("Riding", false)
		lastPositions[player] = nil
		graceUntil[player] = os.clock() + 3
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		riders[player] = nil
		lastPositions[player] = nil
		strikes[player] = nil
		graceUntil[player] = nil
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

return BikeService
