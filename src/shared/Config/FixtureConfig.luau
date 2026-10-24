--!strict
-- FixtureConfig: zones and the light fixtures in them.
--
-- Field guide for each fixture:
--   id                     unique key, also used for tags and state folders
--   nameKey                UIText key for the display name
--   need                   "Required" = safety-critical (path, door, stair, crossing): can be improved, never switched off
--                          "Useful"   = serves people: improve it, do not switch it off
--                          "Unneeded" = QUESTION may switch it off
--   kind                   "Streetlight" | "Floodlight" | "Crossing" (picks the model built in the world)
--   position               lamp head position (X, height, Z) in studs
--   facingDegrees          which way the head faces when aimed (0 = +Z, 90 = +X, 180 = -Z)
--   recommendedBrightness  brightness that lights the area well; anything above counts as over-lighting
--   minBrightness          lowest brightness DIM allows (the safety floor for Required lights)
--   allowedVerbs           which of QUESTION, SHIELD, AIM, DIM, TIME, WARM the menu offers
--   allowedSchedules       which schedules TIME may choose (Required lights: "AllNight" only)
--   questionNoticeKey      UIText key shown when a player asks "Is it needed?"
--   evidenceOnQuestion     evidence key recorded when a player asks (optional)
--   weight                 how much this fixture counts toward the zone score
--   initial                starting (polluted) state; the zone resets to this

local ALL_VERBS = { "QUESTION", "SHIELD", "AIM", "DIM", "TIME", "WARM" }
-- Glarelands are a mirror of Byers Station, offset far away (keep in sync with WorldConfig).
local GLARE = Vector3.new(4000, 0, 0)

-- The three Lantern Lane problem lights. `mirror` flips them east-west for the Glarelands copy.
local function laneFixtures(prefix: string, origin: Vector3, mirror: boolean): { any }
	local flip = if mirror then -1 else 1
	return {
		{
			id = prefix .. "_lamp_corner",
			nameKey = "fixture_lamp_corner",
			need = "Useful",
			kind = "Streetlight",
			position = origin + Vector3.new(-30 * flip, 16, 17),
			facingDegrees = 180,
			recommendedBrightness = 0.5,
			minBrightness = 0.3,
			allowedVerbs = ALL_VERBS,
			allowedSchedules = { "AllNight", "Motion" },
			questionNoticeKey = "question_useful_sidewalk",
			evidenceOnQuestion = nil,
			weight = 1,
			initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" },
		},
		{
			id = prefix .. "_flood_garage",
			nameKey = "fixture_flood_garage",
			need = "Useful",
			kind = "Floodlight",
			position = origin + Vector3.new(6 * flip, 11, 31),
			facingDegrees = 180,
			recommendedBrightness = 0.4,
			minBrightness = 0.2,
			allowedVerbs = ALL_VERBS,
			allowedSchedules = { "AllNight", "Motion", "Curfew" },
			questionNoticeKey = "question_useful_driveway",
			evidenceOnQuestion = nil,
			weight = 1,
			initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 5000, schedule = "AllNight" },
		},
		{
			id = prefix .. "_crossing",
			nameKey = "fixture_crossing",
			need = "Required",
			kind = "Crossing",
			position = origin + Vector3.new(34 * flip, 16, -17),
			facingDegrees = 0,
			recommendedBrightness = 0.7,
			minBrightness = 0.6,
			allowedVerbs = ALL_VERBS,
			allowedSchedules = { "AllNight" },
			questionNoticeKey = "question_required_crossing",
			evidenceOnQuestion = "crossing_needed",
			weight = 1,
			initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 4000, schedule = "AllNight" },
		},
	}
end

local FixtureConfig = {
	Zones = {
		-- Act I tutorial: Lantern Lane in Byers Station, outside the Starlight Hub.
		Home = {
			id = "Home",
			nameKey = "zone_home",
			-- Score at or above this, with every safe path lit, restores the zone.
			restoreThreshold = 70,
			fixtures = laneFixtures("home", Vector3.zero, false),
		},
		-- Leo's Glare Gate: the Glarelands mirror of Lantern Lane.
		Leo = {
			id = "Leo",
			nameKey = "zone_leo",
			restoreThreshold = 75,
			fixtures = laneFixtures("leo", GLARE, true),
		},
	},
}

return FixtureConfig
