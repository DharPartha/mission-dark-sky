--!strict
-- ReportConfig: content for the community lighting proposal players can export.
-- Everything here is fictional and educational (Byers Station is a fictional town).
-- No real addresses, no measurements: evidence comes from simulated game readings.
-- PLACEHOLDER content: the owner must review it before release.

local function t(text: string): { [string]: string }
	return { en = text }
end

local ReportConfig = {
	-- Format id written on the first line. The companion website checks it.
	FormatHeader = "DARKSKY-REPORT v1",
	Title = t("Community Lighting Proposal"),
	SourceNote = t("Simulated game evidence from The Dark Sky (Roblox). Not real measurements."),
	TownNote = t("Byers Station is a fictional town."),

	-- One entry per place a player can write about (zones they restored).
	Places = {
		Home = {
			location = t("Lantern Lane, Byers Station (fictional)"),
			fixture = t("Residential streetlight, garage floodlight, and a crosswalk light"),
			problem = t("Bright, unshielded lights sent glare into eyes and windows and light into the sky."),
			alternatives = {
				{ text = t("Shield and aim the lights down, then dim to what the sidewalk needs"), pros = t("Paths stay lit; less glare and skyglow"), cons = t("An adult or the owner has to arrange the change") },
				{ text = t("Switch off every light on the street"), pros = t("Darker sky"), cons = t("Unsafe: the crossing and sidewalk need light") },
				{ text = t("Make every light brighter"), pros = t("Feels bright"), cons = t("More glare, more wasted energy, more skyglow") },
			},
			recommendations = {
				{ id = "fix_all", text = t("Shield, aim down, dim, and warm all three lights; keep the crossing light on all night.") },
				{ id = "worst_first", text = t("Start with the brightest glare source, then review the other lights.") },
			},
			essential = t("The crosswalk light stays on all night at a safe level."),
		},
		Leo = {
			location = t("Leo's Glare Gate, the Glarelands mirror of Lantern Lane (fictional)"),
			fixture = t("Streetlights and a floodlight near homes and a crossing"),
			problem = t("Unshielded lights aimed outward caused glare for walkers and light trespass into homes."),
			alternatives = {
				{ text = t("Shield the lights and aim them at the ground people use"), pros = t("Useful light where it's needed; safe shadow lanes"), cons = t("Needs the right shields or fixtures") },
				{ text = t("Switch off all the lights"), pros = t("No glare"), cons = t("Unsafe for the crossing and sidewalks") },
				{ text = t("Keep the lights as they are"), pros = t("No work needed"), cons = t("Glare and light trespass continue") },
			},
			recommendations = {
				{ id = "shield_aim", text = t("Shield and aim every light down; dim each to the lowest level that still works.") },
				{ id = "crossing_first", text = t("Improve the crossing light first, keeping it on, then fix the floodlight.") },
			},
			essential = t("The crossing light stays on all night."),
		},
		Orion = {
			location = t("Orion's Spire, mirrored sports fields (fictional)"),
			fixture = t("Sports field floodlights, a scoreboard uplight, and an exit path light"),
			problem = t("Floodlights aimed up and left on after games created skyglow and wasted energy."),
			alternatives = {
				{ text = t("Aim floods at the field and switch them off soon after games"), pros = t("Light for play, dark sky after"), cons = t("Needs timers and a schedule") },
				{ text = t("Leave everything on all night"), pros = t("No schedule to manage"), cons = t("Most waste and skyglow") },
				{ text = t("Switch everything off, including the exit"), pros = t("Darkest"), cons = t("Unsafe exit route") },
			},
			recommendations = {
				{ id = "aim_time", text = t("Aim the floods down at the field, add timers after games, and remove the uplight.") },
				{ id = "timers_first", text = t("Add timers first, then plan to replace the up-aimed floods.") },
			},
			essential = t("The exit path light stays on whenever people leave the field."),
		},
		Scorpius = {
			location = t("Scorpius Meadow, mirrored creek and meadow (fictional)"),
			fixture = t("A trail light, a shed floodlight, and a decorative creek light"),
			problem = t("Light spilled into the meadow and creek, and very blue-white light added to it."),
			alternatives = {
				{ text = t("Shield and aim the shed light, use warmer light, remove the creek accent"), pros = t("Less spill into habitat; trail stays safe"), cons = t("Color is one factor, so spill must be fixed too") },
				{ text = t("Only change the color to warm"), pros = t("Simple"), cons = t("Spill into the meadow continues") },
				{ text = t("Switch off the trail light too"), pros = t("Darker meadow"), cons = t("Unsafe for walkers") },
			},
			recommendations = {
				{ id = "spill_and_color", text = t("Stop the spill first (shield, aim, dim), then use warm light where suitable.") },
				{ id = "remove_accent", text = t("Remove the decorative creek light and fix the shed light; keep the trail lit.") },
			},
			essential = t("The trail light stays on for walkers."),
		},
		Cetus = {
			location = t("Cetus Pond, mirrored pond and dock (fictional)"),
			fixture = t("A dock edge light, a fountain uplight, a boathouse floodlight, and a path lamp"),
			problem = t("Glare bounced off the water and hid the dock edge; decorative light shone up for show."),
			alternatives = {
				{ text = t("Aim the dock and boathouse lights down; time the boathouse light; remove the uplight"), pros = t("Safe dock edge, less glare on the water"), cons = t("Needs timers and new aiming") },
				{ text = t("Light the whole pond brightly"), pros = t("Looks bright"), cons = t("More glare can make the edge harder to see") },
				{ text = t("Switch off the dock light"), pros = t("Dark water"), cons = t("Unsafe: people could miss the edge") },
			},
			recommendations = {
				{ id = "aim_and_time", text = t("Keep the dock edge lit and aimed at the boards; time the boathouse light; remove the uplight.") },
				{ id = "glare_first", text = t("Fix the brightest glare on the water first, then add timers.") },
			},
			essential = t("The dock edge light stays on so nobody slips."),
		},
	},

	-- Trade-offs every recommendation should consider (shown in every report).
	TradeOffs = {
		{ label = t("Safety"), text = t("Paths, doors, stairs, crossings, and exits keep enough light.") },
		{ label = t("Ecology"), text = t("Less light spilling into habitats and the sky; color is one factor among several.") },
		{ label = t("Energy"), text = t("Lower brightness and timers mean less wasted energy (game estimate, not a real figure).") },
		{ label = t("Well-being"), text = t("Less glare in eyes and less light shining into homes at night.") },
	},

	Reflections = {
		{ id = "aim", text = t("I learned light should go where people need it, not into eyes or the sky.") },
		{ id = "safety", text = t("I learned safety lights stay on, and other lights can be smarter.") },
		{ id = "evidence", text = t("I learned to check evidence before believing a claim, even a friendly one.") },
	},

	-- Always added to the next steps, after the player's own pledge actions.
	FixedNextStep = t("Share this proposal with a trusted adult or teacher before doing anything."),

	-- Printed at the end for an adult to fill in OUTSIDE Roblox. Kept separate from game evidence.
	RealWorldNote = t("Optional, completed outside Roblox with a trusted adult. Keep it separate from the simulated evidence above. Never climb, touch, unscrew, or rewire light fixtures."),
}

return ReportConfig
