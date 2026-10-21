-- Prototype parameters only. These are NOT real-world lighting standards.

local Config = {
	Lighting = {
		MinimumLevel = 0.0,
		MaximumLevel = 1.0,
		EmptyBaseline = 0.25,
		IdleTarget = 0.25,
		SafetyMinimum = 0.30,
		RampPerSecond = 0.10,
		PeopleAtFullDemand = 4,
		PeopleDemand = 0.25,
		VehiclesAtFullDemand = 4,
		VehicleDemand = 0.15,
		EventDemand = 0.25,
		RainVisibilityDemand = 0.10,
		CloudyVisibilityDemand = 0.04,
		AmbientContribution = 0.20,
		EnvironmentalReduction = 0.10,
		-- Range must comfortably exceed PoleHeight or the pool never reaches the ground.
		PointLightBrightnessAtFull = 12,
		PointLightRangeAtMin = 34,
		PointLightRangeAtFull = 70,
	},

	-- Demo night. Dark enough that the lamps matter, bright enough to see the lot.
	Scene = {
		ClockTime = 21,
		Brightness = 1.5,
		Ambient = Color3.fromRGB(42, 45, 62),
		OutdoorAmbient = Color3.fromRGB(34, 37, 54),
	},

	Lot = {
		Size = Vector3.new(72, 1, 48),
		Center = Vector3.new(0, 0.5, 0),
		GroundPlaneSize = 400,
		PoleHeight = 18,
		PoleThickness = 0.6,
		LampSize = Vector3.new(2.5, 0.7, 2.5),
	},

	-- Visual stand-ins for simulated activity. These represent sensor counts.
	Activity = {
		-- Real Roblox rigs read better than blocks; blocks are the fallback if
		-- avatar creation fails (it is a yielding call that can error).
		UseAvatarsForPeople = true,
		PersonPivotHeight = 3,
		PersonBodySize = Vector3.new(1.2, 2.2, 0.9),
		PersonHeadSize = 1.1,
		PersonColor = Color3.fromRGB(226, 198, 120),

		VehicleBodySize = Vector3.new(4.4, 1.1, 9),
		VehicleHoodSize = Vector3.new(4.2, 0.7, 2.6),
		VehicleCabinSize = Vector3.new(3.9, 1.2, 4),
		VehicleWheelDiameter = 2.1,
		VehicleWheelThickness = 0.8,
		VehicleColor = Color3.fromRGB(150, 76, 76),
		VehicleWindowColor = Color3.fromRGB(38, 46, 60),
		VehicleWheelColor = Color3.fromRGB(26, 26, 30),
		VehicleHeadlightColor = Color3.fromRGB(255, 244, 214),
	},

	Sensors = {
		MaxPeople = 20,
		MaxVehicles = 20,
		InitialState = {
			people = 0,
			vehicles = 0,
			ambientLight = 0,
			timeOfDay = 23,
			weather = "Clear",
			eventActive = false,
			environmentalSensitivity = 0.25,
		},
		AllowedWeather = { "Clear", "Cloudy", "Rain" },
	},

	Impact = {
		FixedLightingLevel = 1.0,
		TimedLightingLevel = 0.65,
		EstimatedEnergyUnitsPerSecondAtFull = 0.04,
		EstimatedCostPerEnergyUnit = 0.25,
	},

	Network = {
		StateBroadcastSeconds = 0.20,
	},

	Scenarios = {
		DemoStepSeconds = 5,
	},

	Debug = {
		-- When true, brightness ramps between idle and CycleHighTarget so you can
		-- see the transition without sensors. Keep false for a stable empty lot.
		CycleTargets = false,
		CycleHighTarget = 0.80,
		CycleSeconds = 8,
		ShowZoneVolume = true,
		RunAcceptanceTests = true,
	},
}

return Config
