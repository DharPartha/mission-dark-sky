local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))

local SensorService = {}

local currentState: Types.SensorState

local function cloneState(source): Types.SensorState
	return {
		people = source.people,
		vehicles = source.vehicles,
		ambientLight = source.ambientLight,
		timeOfDay = source.timeOfDay,
		weather = source.weather,
		eventActive = source.eventActive,
		environmentalSensitivity = source.environmentalSensitivity,
	}
end

local function isAllowedWeather(weather: string): boolean
	for _, allowed in Config.Sensors.AllowedWeather do
		if weather == allowed then
			return true
		end
	end
	return false
end

function SensorService.init()
	currentState = cloneState(Config.Sensors.InitialState)
end

function SensorService.getState(): Types.SensorState
	return cloneState(currentState)
end

function SensorService.setState(nextState: Types.SensorState)
	currentState = {
		people = math.clamp(math.floor(nextState.people), 0, Config.Sensors.MaxPeople),
		vehicles = math.clamp(math.floor(nextState.vehicles), 0, Config.Sensors.MaxVehicles),
		ambientLight = math.clamp(nextState.ambientLight, 0, 1),
		timeOfDay = math.clamp(nextState.timeOfDay, 0, 24),
		weather = if isAllowedWeather(nextState.weather) then nextState.weather else "Clear",
		eventActive = nextState.eventActive == true,
		environmentalSensitivity = math.clamp(nextState.environmentalSensitivity, 0, 1),
	}
end

function SensorService.applyControl(control: string, value: any): boolean
	local nextState = SensorService.getState()

	if control == "peopleDelta" and typeof(value) == "number" then
		nextState.people += math.clamp(math.floor(value), -1, 1)
	elseif control == "vehiclesDelta" and typeof(value) == "number" then
		nextState.vehicles += math.clamp(math.floor(value), -1, 1)
	elseif control == "ambientDelta" and typeof(value) == "number" then
		nextState.ambientLight += math.clamp(value, -0.1, 0.1)
	elseif control == "timeDelta" and typeof(value) == "number" then
		nextState.timeOfDay = (nextState.timeOfDay + math.clamp(value, -1, 1)) % 24
	elseif control == "weather" and typeof(value) == "string" and isAllowedWeather(value) then
		nextState.weather = value
	elseif control == "toggleEvent" then
		nextState.eventActive = not nextState.eventActive
	else
		return false
	end

	SensorService.setState(nextState)
	return true
end

return SensorService
