local Types = require(script.Parent.Types)

local function state(
	people: number,
	vehicles: number,
	ambientLight: number,
	timeOfDay: number,
	weather: string,
	eventActive: boolean
): Types.SensorState
	return {
		people = people,
		vehicles = vehicles,
		ambientLight = ambientLight,
		timeOfDay = timeOfDay,
		weather = weather,
		eventActive = eventActive,
		environmentalSensitivity = 0.25,
	}
end

local ordered: { Types.ScenarioDefinition } = {
	{
		id = "empty",
		displayName = "Empty Parking Lot",
		description = "Late night with no detected activity.",
		sensorState = state(0, 0, 0.05, 23, "Clear", false),
	},
	{
		id = "pedestrian",
		displayName = "Single Pedestrian",
		description = "One pedestrian enters the zone.",
		sensorState = state(1, 0, 0.05, 23, "Clear", false),
	},
	{
		id = "multiplePedestrians",
		displayName = "Multiple Pedestrians",
		description = "Four pedestrians use the parking lot.",
		sensorState = state(4, 0, 0.05, 23, "Clear", false),
	},
	{
		id = "vehicle",
		displayName = "Vehicle Arrival",
		description = "A vehicle arrives while a pedestrian is present.",
		sensorState = state(1, 1, 0.05, 23, "Clear", false),
	},
	{
		id = "event",
		displayName = "Community Event",
		description = "Several people and vehicles attend an event.",
		sensorState = state(6, 3, 0.05, 21, "Clear", true),
	},
	{
		id = "eventEnds",
		displayName = "Event Ends",
		description = "Activity leaves and the lot returns toward baseline.",
		sensorState = state(0, 0, 0.05, 23, "Clear", false),
	},
	{
		id = "rain",
		displayName = "Rain",
		description = "Rain adds a simulated visibility adjustment.",
		sensorState = state(1, 1, 0.05, 23, "Rain", false),
	},
	{
		id = "sunrise",
		displayName = "Sunrise",
		description = "Ambient daylight reduces artificial lighting demand.",
		sensorState = state(0, 0, 0.95, 7.5, "Clear", false),
	},
}

local byId: { [string]: Types.ScenarioDefinition } = {}
for _, scenario in ordered do
	byId[scenario.id] = scenario
end

local ScenarioDefinitions = {}

function ScenarioDefinitions.getAll(): { Types.ScenarioDefinition }
	return ordered
end

function ScenarioDefinitions.getById(id: string): Types.ScenarioDefinition?
	return byId[id]
end

return ScenarioDefinitions
