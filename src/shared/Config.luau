-- Prototype parameters only. These are NOT real-world lighting standards.

local Config = {
    Lighting = {
        MinimumLevel = 0.0,
        MaximumLevel = 1.0,
        EmptyBaseline = 0.25,
        SafetyMinimum = 0.30,
        RampPerSecond = 0.10,
    },

    Sensors = {
        MaxPeople = 20,
        MaxVehicles = 20,
    },
}

return Config
