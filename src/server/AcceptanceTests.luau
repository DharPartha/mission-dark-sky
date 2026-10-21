local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local LightingMath = require(Shared:WaitForChild("LightingMath"))

local AcceptanceTests = {}

local function input(overrides)
	local result = table.clone(Config.Sensors.InitialState)
	for key, value in overrides do
		result[key] = value
	end
	return result
end

function AcceptanceTests.run()
	local empty = LightingMath.calculateTargetLevel(input({}))
	local pedestrian = LightingMath.calculateTargetLevel(input({ people = 1 }))
	local vehicle = LightingMath.calculateTargetLevel(input({ vehicles = 1 }))
	local event = LightingMath.calculateTargetLevel(input({ eventActive = true }))
	local sunrise = LightingMath.calculateTargetLevel(input({
		ambientLight = 1,
		timeOfDay = 8,
	}))
	local extreme = LightingMath.calculateTargetLevel(input({
		people = 999,
		vehicles = 999,
		eventActive = true,
		weather = "Rain",
	}))

	assert(empty >= Config.Lighting.SafetyMinimum, "Empty nighttime target must respect safety floor")
	assert(pedestrian > empty, "Pedestrian must increase target")
	assert(vehicle > empty, "Vehicle must increase target")
	assert(event > empty, "Event must increase target")
	assert(sunrise < empty, "Sunrise must reduce artificial lighting")
	assert(extreme <= Config.Lighting.MaximumLevel, "Extreme target must remain in bounds")
	assert(
		LightingMath.calculateTargetLevel(input({ people = 2 })) == LightingMath.calculateTargetLevel(input({ people = 2 })),
		"Identical inputs must be deterministic"
	)

	print("[MissionDarkSky] Acceptance checks passed: engine inputs, bounds, sunrise, repeatability")
end

return AcceptanceTests
