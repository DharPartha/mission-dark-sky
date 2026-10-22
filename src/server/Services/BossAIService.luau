--!strict
-- BossAIService: Leo, the Blinded Lion (Milestone 1 tutorial encounter).
--
-- While active, Leo roars on a fixed cycle: a readable telegraph first, then players
-- standing inside a glare zone get temporary Glare (slowdown + screen washout on their
-- client). Glare zones come straight from fixture state, so shielding and aiming lights
-- literally creates the safe shadow lanes. No damage, no death screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))

local GameStateService = require(script.Parent:WaitForChild("GameStateService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BossAIService = {}

local leo: WorldBuilder.LeoParts
local glareEvent: RemoteEvent
local noticeEvent: RemoteEvent
-- Bumped on every start/stop so old loops notice they are stale and exit.
local generation = 0
local glareTokens: { [Player]: number } = {}

local function setLeoColor(color: Color3, beamTransparency: number)
	for _, star in leo.stars do
		star.Color = color
	end
	for _, beam in leo.beams do
		beam.Color = ColorSequence.new(color)
		beam.Transparency = NumberSequence.new(beamTransparency)
	end
end

local function playersInGlare(): { Player }
	local config = BossConfig.Leo
	local zones = {}
	local states = GameStateService.getZoneStates(config.zoneId)
	for fixtureId, state in states do
		local def = GameStateService.getDefinition(fixtureId)
		local zone = if def then DarknessMath.glareZone(def, state) else nil
		if zone then
			table.insert(zones, zone)
		end
	end

	local hit = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			local position = rootPart.Position
			for _, zone in zones do
				local dx, dz = position.X - zone.x, position.Z - zone.z
				if math.sqrt(dx * dx + dz * dz) <= zone.radius then
					table.insert(hit, player)
					break
				end
			end
		end
	end
	return hit
end

local function applyGlare(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local token = (glareTokens[player] or 0) + 1
	glareTokens[player] = token
	humanoid.WalkSpeed = Tuning.Glare.SlowWalkSpeed
	glareEvent:FireClient(player, "hit", Tuning.Glare.DurationSeconds)
	noticeEvent:FireClient(player, "notice_glare_hit")
	task.delay(Tuning.Glare.DurationSeconds, function()
		-- Only the newest hit restores speed, so overlapping hits extend the effect.
		if glareTokens[player] == token and humanoid.Parent then
			humanoid.WalkSpeed = Tuning.Glare.NormalWalkSpeed
		end
	end)
end

local function roarLoop(myGeneration: number)
	local config = BossConfig.Leo
	while generation == myGeneration do
		task.wait(config.roarIntervalSeconds - config.telegraphSeconds)
		if generation ~= myGeneration then
			return
		end
		-- Telegraph: Leo flares bright and every client shows a warning banner.
		glareEvent:FireAllClients("telegraph", config.telegraphSeconds)
		setLeoColor(Color3.fromRGB(255, 200, 120), 0)
		task.wait(config.telegraphSeconds)
		if generation ~= myGeneration then
			return
		end
		for _, player in playersInGlare() do
			applyGlare(player)
		end
		setLeoColor(config.corruptedColor, 0.3)
	end
end

function BossAIService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	leo = builtWorld.leo
	glareEvent = remotes.GlareEvent
	noticeEvent = remotes.Notice
	Players.PlayerRemoving:Connect(function(player)
		glareTokens[player] = nil
	end)
end

function BossAIService.setCorrupted()
	generation += 1
	setLeoColor(BossConfig.Leo.corruptedColor, 0.3)
	for _, eye in leo.eyes do
		eye.Transparency = 0
	end
end

function BossAIService.startEncounter()
	generation += 1
	if FeatureFlags.EnableLeoRoar then
		task.spawn(roarLoop, generation)
	end
end

-- Calms Leo: stops the roar, clears any Glare, and fades the stars to their true color.
function BossAIService.restore()
	generation += 1
	for player in glareTokens do
		glareTokens[player] = nil
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Tuning.Glare.NormalWalkSpeed
		end
	end
	local restored = BossConfig.Leo.restoredColor
	local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	for _, star in leo.stars do
		TweenService:Create(star, tweenInfo, { Color = restored }):Play()
	end
	for _, beam in leo.beams do
		beam.Color = ColorSequence.new(restored)
		beam.Transparency = NumberSequence.new(0.15)
	end
	for _, eye in leo.eyes do
		TweenService:Create(eye, tweenInfo, { Transparency = 1 }):Play()
	end
end

return BossAIService
