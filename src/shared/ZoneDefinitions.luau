local Types = require(script.Parent.Types)

export type FixtureDefinition = Types.FixtureDefinition
export type ZoneDefinition = Types.ZoneDefinition

-- Four corner poles around a compact stall grid. Offsets are in studs from lot center.
local parkingLot: Types.ZoneDefinition = {
	id = "parkingLot",
	displayName = "Parking Lot",
	fixtures = {
		{ id = "PL-1", offset = Vector3.new(-28, 0, -16) },
		{ id = "PL-2", offset = Vector3.new(28, 0, -16) },
		{ id = "PL-3", offset = Vector3.new(-28, 0, 16) },
		{ id = "PL-4", offset = Vector3.new(28, 0, 16) },
	},
}

-- Display slots for simulated activity. Counts above the slot count are still
-- used by the engine; only the visible markers are capped.
local peopleSlots: { Vector3 } = {
	Vector3.new(-24, 0, 18),
	Vector3.new(-16, 0, 20),
	Vector3.new(-8, 0, 17),
	Vector3.new(0, 0, 19),
	Vector3.new(8, 0, 18),
	Vector3.new(16, 0, 20),
	Vector3.new(24, 0, 17),
	Vector3.new(-20, 0, 12),
	Vector3.new(4, 0, 12),
	Vector3.new(20, 0, 13),
}

local vehicleSlots: { Vector3 } = {
	Vector3.new(-25, 0, 0),
	Vector3.new(-15, 0, 0),
	Vector3.new(-5, 0, 0),
	Vector3.new(5, 0, 0),
	Vector3.new(15, 0, 0),
	Vector3.new(25, 0, 0),
}

local ZoneDefinitions = {
	parkingLot = parkingLot,
}

function ZoneDefinitions.getParkingLot(): Types.ZoneDefinition
	return parkingLot
end

function ZoneDefinitions.getPeopleSlots(): { Vector3 }
	return peopleSlots
end

function ZoneDefinitions.getVehicleSlots(): { Vector3 }
	return vehicleSlots
end

return ZoneDefinitions
