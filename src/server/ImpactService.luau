local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))

local ImpactService = {}

local adaptiveEnergy = 0
local fixedEnergy = 0
local timedEnergy = 0

function ImpactService.reset()
	adaptiveEnergy = 0
	fixedEnergy = 0
	timedEnergy = 0
end

function ImpactService.step(dt: number, currentLighting: number)
	local impact = Config.Impact
	adaptiveEnergy += currentLighting * impact.EstimatedEnergyUnitsPerSecondAtFull * dt
	fixedEnergy += impact.FixedLightingLevel * impact.EstimatedEnergyUnitsPerSecondAtFull * dt
	timedEnergy += impact.TimedLightingLevel * impact.EstimatedEnergyUnitsPerSecondAtFull * dt
end

function ImpactService.getMetrics(
	sensors: Types.SensorState,
	currentLighting: number
): Types.ImpactMetrics
	local changePercent = 0
	if fixedEnergy > 0 then
		changePercent = ((adaptiveEnergy - fixedEnergy) / fixedEnergy) * 100
	end

	local hasActivity = sensors.people > 0 or sensors.vehicles > 0 or sensors.eventActive
	local safetyActivityStatus = if hasActivity then "Activity detected" else "No current activity"
	local environmentStatus = if currentLighting <= Config.Lighting.SafetyMinimum + 0.01
		then "Lower light impact"
		else "Activity lighting"

	return {
		estimatedEnergy = adaptiveEnergy,
		estimatedCost = adaptiveEnergy * Config.Impact.EstimatedCostPerEnergyUnit,
		fixedEnergy = fixedEnergy,
		timedEnergy = timedEnergy,
		adaptiveChangePercent = changePercent,
		safetyActivityStatus = safetyActivityStatus,
		environmentStatus = environmentStatus,
	}
end

return ImpactService
