local Config = require(script.Parent.Config)
local Types = require(script.Parent.Types)

local LightingMath = {}

function LightingMath.clamp(value: number, minimum: number, maximum: number): number
    return math.max(minimum, math.min(maximum, value))
end

function LightingMath.calculateDecision(input: Types.SensorState): Types.LightingDecision
	local lighting = Config.Lighting
	local safety = lighting.SafetyMinimum
	local activity = math.min(input.people / lighting.PeopleAtFullDemand, 1) * lighting.PeopleDemand
	local vehicleDemand = math.min(input.vehicles / lighting.VehiclesAtFullDemand, 1)
		* lighting.VehicleDemand
	local eventDemand = if input.eventActive then lighting.EventDemand else 0
	local visibilityAdjustment = 0
	if input.weather == "Rain" then
		visibilityAdjustment = lighting.RainVisibilityDemand
	elseif input.weather == "Cloudy" then
		visibilityAdjustment = lighting.CloudyVisibilityDemand
	end
	local ambientContribution = LightingMath.clamp(input.ambientLight, 0, 1)
		* lighting.AmbientContribution
	local environmentalReduction = LightingMath.clamp(input.environmentalSensitivity, 0, 1)
		* lighting.EnvironmentalReduction

	local target = safety
		+ activity
		+ vehicleDemand
		+ eventDemand
		+ visibilityAdjustment
		- ambientContribution
		- environmentalReduction

	-- In bright daytime, artificial light may fall below the nighttime safety floor.
	-- At night, safety is a constraint and cannot be subtracted away.
	local isDaytime = input.ambientLight >= 0.75 or (input.timeOfDay >= 7 and input.timeOfDay < 19)
	local lowerBound = if isDaytime then lighting.MinimumLevel else safety
	target = LightingMath.clamp(target, lowerBound, lighting.MaximumLevel)

	return {
		targetLevel = target,
		safetyRequirement = safety,
		activityDemand = activity,
		vehicleDemand = vehicleDemand,
		eventDemand = eventDemand,
		visibilityAdjustment = visibilityAdjustment,
		ambientContribution = ambientContribution,
		environmentalReduction = environmentalReduction,
	}
end

function LightingMath.calculateTargetLevel(input: Types.SensorState): number
	return LightingMath.calculateDecision(input).targetLevel
end

return LightingMath
