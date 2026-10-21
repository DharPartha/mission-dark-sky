local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

-- The world is built at runtime, so hold characters back until ground exists.
-- Without this the character spawns into empty space and falls.
Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
-- Fail loudly instead of yielding forever when Rojo has only partially synced.
local function requireFrom(container: Instance, name: string)
	local module = container:FindFirstChild(name)
	if module == nil then
		error(
			string.format(
				"[MissionDarkSky] '%s' is missing from %s. Stop the game, reconnect Rojo in edit mode, then Play again.",
				name,
				container:GetFullName()
			),
			0
		)
	end
	return require(module)
end

local Config = requireFrom(Shared, "Config")

local ParkingLotBuilder = requireFrom(script.Parent, "ParkingLotBuilder")
local LightingService = requireFrom(script.Parent, "LightingService")
local SensorService = requireFrom(script.Parent, "SensorService")
local OptimizationService = requireFrom(script.Parent, "OptimizationService")
local ImpactService = requireFrom(script.Parent, "ImpactService")
local ScenarioService = requireFrom(script.Parent, "ScenarioService")
local AcceptanceTests = requireFrom(script.Parent, "AcceptanceTests")
local ActivityVisualizer = requireFrom(script.Parent, "ActivityVisualizer")

print("[MissionDarkSky] Bootstrap starting")

if Config.Debug.RunAcceptanceTests then
	AcceptanceTests.run()
end

local lotFolder = ParkingLotBuilder.build()
LightingService.init(lotFolder)
ActivityVisualizer.build(lotFolder)
SensorService.init()
ImpactService.reset()
ScenarioService.apply("empty")

local initialDecision = OptimizationService.update(SensorService.getState())
LightingService.snapAllToTarget()

print(string.format(
	"[MissionDarkSky] MVP ready: %d fixtures, initial target %d%%",
	LightingService.getFixtureCount(),
	math.floor(initialDecision.targetLevel * 100 + 0.5)
))

-- World exists now, so characters can safely load.
Players.CharacterAutoLoads = true
Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)
for _, player in Players:GetPlayers() do
	player:LoadCharacter()
end

local existingRemotes = Shared:FindFirstChild("Remotes")
if existingRemotes then
	existingRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = Shared

local commandEvent = Instance.new("RemoteEvent")
commandEvent.Name = "SimulationCommand"
commandEvent.Parent = remotes

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "SimulationState"
stateEvent.Parent = remotes

local function applySceneForSensors(sensors)
	Lighting.ClockTime = sensors.timeOfDay
	local daylight = math.clamp(sensors.ambientLight, 0, 1)
	Lighting.Brightness = Config.Scene.Brightness + daylight * 1.5
	Lighting.Ambient = Config.Scene.Ambient:Lerp(Color3.fromRGB(120, 120, 125), daylight)
	Lighting.OutdoorAmbient = Config.Scene.OutdoorAmbient:Lerp(Color3.fromRGB(135, 135, 140), daylight)
end

local function broadcastState()
	local sensors = SensorService.getState()
	local decision = OptimizationService.getLastDecision()
	if decision == nil then
		return
	end
	local currentLighting = LightingService.getAverageLevel()
	local scenarioId, scenarioName = ScenarioService.getCurrent()
	stateEvent:FireAllClients({
		scenarioId = scenarioId,
		scenarioName = scenarioName,
		sensors = sensors,
		decision = decision,
		currentLighting = currentLighting,
		metrics = ImpactService.getMetrics(sensors, currentLighting),
	})
end

commandEvent.OnServerEvent:Connect(function(_player, command, value)
	if command == "scenario" and typeof(value) == "string" then
		ScenarioService.apply(value)
	elseif command == "startDemo" then
		ScenarioService.startDemo()
	elseif typeof(command) == "string" and SensorService.applyControl(command, value) then
		ScenarioService.markManual()
	else
		return
	end

	local sensors = SensorService.getState()
	OptimizationService.update(sensors)
	applySceneForSensors(sensors)
	broadcastState()
end)

local broadcastElapsed = 0
RunService.Heartbeat:Connect(function(dt)
	local sensors = SensorService.getState()
	OptimizationService.update(sensors)
	ActivityVisualizer.setCounts(sensors.people, sensors.vehicles)
	LightingService.step(dt)
	ImpactService.step(dt, LightingService.getAverageLevel())
	applySceneForSensors(sensors)

	broadcastElapsed += dt
	if broadcastElapsed >= Config.Network.StateBroadcastSeconds then
		broadcastElapsed = 0
		broadcastState()
	end
end)
