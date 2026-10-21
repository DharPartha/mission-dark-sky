local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local ScenarioDefinitions = require(Shared:WaitForChild("ScenarioDefinitions"))

local SensorService = require(script.Parent:WaitForChild("SensorService"))

local ScenarioService = {}

local currentId = "empty"
local currentName = "Empty Parking Lot"
local demoToken = 0

function ScenarioService.apply(id: string): boolean
	local scenario = ScenarioDefinitions.getById(id)
	if scenario == nil then
		return false
	end

	demoToken += 1
	currentId = scenario.id
	currentName = scenario.displayName
	SensorService.setState(scenario.sensorState)
	return true
end

function ScenarioService.markManual()
	demoToken += 1
	currentId = "manual"
	currentName = "Manual Controls"
end

function ScenarioService.startDemo()
	demoToken += 1
	local token = demoToken
	task.spawn(function()
		for _, scenario in ScenarioDefinitions.getAll() do
			if token ~= demoToken then
				return
			end
			currentId = scenario.id
			currentName = "Demo: " .. scenario.displayName
			SensorService.setState(scenario.sensorState)
			task.wait(Config.Scenarios.DemoStepSeconds)
		end
	end)
end

function ScenarioService.getCurrent(): (string, string)
	return currentId, currentName
end

return ScenarioService
