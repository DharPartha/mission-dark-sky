local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local LightingMath = require(Shared:WaitForChild("LightingMath"))
local Types = require(Shared:WaitForChild("Types"))

local LightingService = require(script.Parent:WaitForChild("LightingService"))

local OptimizationService = {}

local lastDecision: Types.LightingDecision? = nil

function OptimizationService.update(sensorState: Types.SensorState): Types.LightingDecision
	local decision = LightingMath.calculateDecision(sensorState)
	lastDecision = decision
	LightingService.setAllTargets(decision.targetLevel)
	return decision
end

function OptimizationService.getLastDecision(): Types.LightingDecision?
	return lastDecision
end

return OptimizationService
