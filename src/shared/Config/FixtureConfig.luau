--!strict
-- FixtureConfig: zones and the light fixtures in them.
--
-- Field guide for each fixture:
--   id                     unique key, also used for tags and state folders
--   nameKey                UIText key for the display name
--   need                   "Required" = safety-critical (path, door, stair, crossing): can be improved, never switched off
--                          "Useful"   = serves people: improve it, do not switch it off
--                          "Unneeded" = QUESTION may switch it off
--   kind                   "Streetlight" | "Floodlight" | "Crossing" | "Ground" (picks the model)
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

-- Builds a fixture definition from the fields that differ, with shared defaults.
local function fixture(fields: { [string]: any }): { [string]: any }
	local def = {
		facingDegrees = 0,
		allowedVerbs = ALL_VERBS,
		allowedSchedules = { "AllNight", "Motion", "Curfew" },
		evidenceOnQuestion = nil,
		weight = 1,
	}
	for key, value in fields do
		def[key] = value
	end
	return def
end

local function glare(x: number, y: number, z: number): Vector3
	return GLARE + Vector3.new(x, y, z)
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
		-- Leo's Glare Gate: the Glarelands mirror of Lantern Lane. Lesson: shield and aim.
		Leo = {
			id = "Leo",
			nameKey = "zone_leo",
			restoreThreshold = 75,
			fixtures = laneFixtures("leo", GLARE, true),
		},
		-- Orion's Spire: mirrored sports fields. Lesson: aim at the activity, time it after events.
		Orion = {
			id = "Orion",
			nameKey = "zone_orion",
			restoreThreshold = 75,
			fixtures = {
				fixture({
					id = "orion_flood_north",
					nameKey = "fixture_orion_flood",
					need = "Useful",
					kind = "Streetlight",
					position = glare(-50, 30, 214),
					facingDegrees = 180,
					recommendedBrightness = 0.6,
					minBrightness = 0.3,
					questionNoticeKey = "question_orion_flood",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Up", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "orion_flood_south",
					nameKey = "fixture_orion_flood",
					need = "Useful",
					kind = "Streetlight",
					position = glare(-50, 30, 116),
					facingDegrees = 0,
					recommendedBrightness = 0.6,
					minBrightness = 0.3,
					questionNoticeKey = "question_orion_flood",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "orion_uplight",
					nameKey = "fixture_orion_uplight",
					need = "Unneeded",
					kind = "Ground",
					position = glare(-50, 1.5, 222),
					facingDegrees = 180,
					recommendedBrightness = 0.3,
					minBrightness = 0,
					questionNoticeKey = "question_orion_uplight",
					initial = { on = true, brightness = 0.9, shielded = false, aim = "Up", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "orion_exit",
					nameKey = "fixture_orion_exit",
					need = "Required",
					kind = "Crossing",
					position = glare(30, 14, 165),
					facingDegrees = 270,
					recommendedBrightness = 0.6,
					minBrightness = 0.5,
					allowedSchedules = { "AllNight" },
					questionNoticeKey = "question_orion_exit",
					evidenceOnQuestion = "orion_exit_needed",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 4000, schedule = "AllNight" },
				}),
			},
		},
		-- Scorpius Meadow: mirrored creek and meadow. Lesson: cut spill into habitat; color is
		-- one factor among several.
		Scorpius = {
			id = "Scorpius",
			nameKey = "zone_scorpius",
			restoreThreshold = 75,
			fixtures = {
				fixture({
					id = "scorp_path",
					nameKey = "fixture_scorp_path",
					need = "Required",
					kind = "Crossing",
					position = glare(-40, 11, -265),
					facingDegrees = 180,
					recommendedBrightness = 0.5,
					minBrightness = 0.4,
					allowedSchedules = { "AllNight" },
					questionNoticeKey = "question_scorp_path",
					initial = { on = true, brightness = 0.9, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "scorp_shed_flood",
					nameKey = "fixture_scorp_flood",
					need = "Useful",
					kind = "Floodlight",
					position = glare(-120, 9, -243.5),
					facingDegrees = 180,
					recommendedBrightness = 0.4,
					minBrightness = 0.2,
					questionNoticeKey = "question_scorp_flood",
					evidenceOnQuestion = "spill_into_habitat",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "scorp_creek_accent",
					nameKey = "fixture_scorp_accent",
					need = "Unneeded",
					kind = "Ground",
					position = glare(-60, 1.5, -288),
					facingDegrees = 180,
					recommendedBrightness = 0.3,
					minBrightness = 0,
					questionNoticeKey = "question_scorp_accent",
					initial = { on = true, brightness = 0.8, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" },
				}),
			},
		},
		-- Cetus Pond: mirrored pond and dock. Lesson: safe access and less spill can coexist.
		Cetus = {
			id = "Cetus",
			nameKey = "zone_cetus",
			restoreThreshold = 75,
			fixtures = {
				fixture({
					id = "cetus_dock",
					nameKey = "fixture_cetus_dock",
					need = "Required",
					kind = "Crossing",
					position = glare(170, 9, -143),
					facingDegrees = 90,
					recommendedBrightness = 0.6,
					minBrightness = 0.5,
					allowedSchedules = { "AllNight" },
					questionNoticeKey = "question_cetus_dock",
					evidenceOnQuestion = "dock_glare",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 4000, schedule = "AllNight" },
				}),
				fixture({
					id = "cetus_fountain",
					nameKey = "fixture_cetus_fountain",
					need = "Unneeded",
					kind = "Ground",
					position = glare(215, 1.5, -150),
					recommendedBrightness = 0.3,
					minBrightness = 0,
					questionNoticeKey = "question_cetus_fountain",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Up", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "cetus_boathouse",
					nameKey = "fixture_cetus_boathouse",
					need = "Useful",
					kind = "Floodlight",
					position = glare(240, 9, -197.5),
					facingDegrees = 0,
					recommendedBrightness = 0.4,
					minBrightness = 0.2,
					questionNoticeKey = "question_cetus_boathouse",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 5000, schedule = "AllNight" },
				}),
				fixture({
					id = "cetus_path",
					nameKey = "fixture_cetus_path",
					need = "Useful",
					kind = "Streetlight",
					position = glare(258, 14, -120),
					facingDegrees = 270,
					recommendedBrightness = 0.5,
					minBrightness = 0.3,
					allowedSchedules = { "AllNight", "Motion" },
					questionNoticeKey = "question_cetus_path",
					initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" },
				}),
			},
		},
	},

	-- Town echoes: non-interactive lights in Byers Station that match each realm. When the
	-- realm is restored, its echoes switch to their responsible state, so a fix in the
	-- Glarelands visibly changes the matching place in town.
	Echoes = {
		Leo = {
			fixture({ id = "echo_mainroad_1", nameKey = "fixture_lamp_corner", need = "Useful", kind = "Streetlight", position = Vector3.new(164, 16, -70), facingDegrees = 270, recommendedBrightness = 0.5, minBrightness = 0.3, questionNoticeKey = "question_useful_sidewalk", initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" } }),
			fixture({ id = "echo_mainroad_2", nameKey = "fixture_lamp_corner", need = "Useful", kind = "Streetlight", position = Vector3.new(164, 16, 70), facingDegrees = 270, recommendedBrightness = 0.5, minBrightness = 0.3, questionNoticeKey = "question_useful_sidewalk", initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" } }),
		},
		Orion = {
			fixture({ id = "echo_field_ne", nameKey = "fixture_orion_flood", need = "Useful", kind = "Streetlight", position = Vector3.new(129, 30, 214), facingDegrees = 225, recommendedBrightness = 0.6, minBrightness = 0.3, questionNoticeKey = "question_orion_flood", initial = { on = true, brightness = 1.0, shielded = false, aim = "Up", colorTempK = 5000, schedule = "AllNight" } }),
			fixture({ id = "echo_field_sw", nameKey = "fixture_orion_flood", need = "Useful", kind = "Streetlight", position = Vector3.new(-29, 30, 116), facingDegrees = 45, recommendedBrightness = 0.6, minBrightness = 0.3, questionNoticeKey = "question_orion_flood", initial = { on = true, brightness = 1.0, shielded = false, aim = "Up", colorTempK = 5000, schedule = "AllNight" } }),
		},
		Scorpius = {
			fixture({ id = "echo_meadow_1", nameKey = "fixture_scorp_path", need = "Required", kind = "Streetlight", position = Vector3.new(40, 11, -232), facingDegrees = 180, recommendedBrightness = 0.5, minBrightness = 0.4, allowedSchedules = { "AllNight" }, questionNoticeKey = "question_scorp_path", initial = { on = true, brightness = 0.9, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" } }),
			fixture({ id = "echo_meadow_2", nameKey = "fixture_scorp_path", need = "Required", kind = "Streetlight", position = Vector3.new(130, 11, -232), facingDegrees = 180, recommendedBrightness = 0.5, minBrightness = 0.4, allowedSchedules = { "AllNight" }, questionNoticeKey = "question_scorp_path", initial = { on = true, brightness = 0.9, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" } }),
		},
		Cetus = {
			fixture({ id = "echo_dock", nameKey = "fixture_cetus_dock", need = "Required", kind = "Streetlight", position = Vector3.new(-170, 9, -143), facingDegrees = 270, recommendedBrightness = 0.6, minBrightness = 0.5, allowedSchedules = { "AllNight" }, questionNoticeKey = "question_cetus_dock", initial = { on = true, brightness = 1.0, shielded = false, aim = "Out", colorTempK = 4000, schedule = "AllNight" } }),
			fixture({ id = "echo_pond_path", nameKey = "fixture_cetus_path", need = "Useful", kind = "Streetlight", position = Vector3.new(-150, 14, -100), facingDegrees = 180, recommendedBrightness = 0.5, minBrightness = 0.3, questionNoticeKey = "question_cetus_path", initial = { on = true, brightness = 1.0, shielded = false, aim = "Angled", colorTempK = 5000, schedule = "AllNight" } }),
		},
	},
}

return FixtureConfig
