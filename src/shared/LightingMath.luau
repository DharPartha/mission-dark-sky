local Config = require(script.Parent.Config)

local LightingMath = {}

function LightingMath.clamp(value: number, minimum: number, maximum: number): number
    return math.max(minimum, math.min(maximum, value))
end

function LightingMath.calculateTargetLevel(input): number
    local safety = Config.Lighting.SafetyMinimum
    local activity = math.min(input.people / 4, 1) * 0.25
    local vehicleDemand = math.min(input.vehicles / 4, 1) * 0.15
    local eventDemand = input.eventActive and 0.25 or 0
    local ambientContribution = input.ambientLight * 0.20
    local environmentalReduction = input.environmentalSensitivity * 0.10

    local target = safety
        + activity
        + vehicleDemand
        + eventDemand
        - ambientContribution
        - environmentalReduction

    return LightingMath.clamp(
        target,
        Config.Lighting.MinimumLevel,
        Config.Lighting.MaximumLevel
    )
end

return LightingMath
