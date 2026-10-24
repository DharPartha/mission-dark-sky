--!strict
-- MoonTipsConfig: the Moon's tips for the "Doubt it!" mechanic, and the in-game evidence
-- players can collect to check them.
--
-- Tip fields:
--   id            unique key
--   lineId        DialogueConfig line the Moon says
--   isMisleading  true = the correct call is "Doubt it!"; false = "Sounds right"
--   evidenceKey   Evidence entry that disproves (or supports) the tip. It must be findable
--                 in the world BEFORE the tip is given.
--   trigger       when the tip plays (documentation): "rift", "afterRealm:<ZoneId>", or "finale".
--                 MissionConfig moonTip/claims steps decide the actual order.
--   onDoubt       DialogueConfig sequence played when the team picks "Doubt it!"
--   onAgree       DialogueConfig sequence played when the team picks "Sounds right"
--   onTie         sequence for a tied vote (the Moon pushes her answer; no token)
--
-- Baseline design: 10 tips, 6 misleading and 4 true (all shipped).
-- Evidence below describes in-game observations, not real-world facts.

local MoonTipsConfig = {
	Evidence = {
		crossing_needed = {
			title = { en = "Crossing light is needed" },
			text = { en = "The crossing sign and the light check both say walkers need this light." },
		},
		glare_reading = {
			title = { en = "Lux Lens glare reading" },
			text = { en = "Unshielded lights scored high glare. The problem is where light goes." },
		},
		shield_cuts_glare = {
			title = { en = "Shields cut glare" },
			text = { en = "Adding a shield lowered glare while the path stayed lit." },
		},
		orion_exit_needed = {
			title = { en = "Exit path light is needed" },
			text = { en = "People leave the field along this path. Its light stays on all night." },
		},
		spill_into_habitat = {
			title = { en = "Spill reaches the meadow" },
			text = { en = "The shed light also floods the meadow. Where light lands matters, not only its color." },
		},
		dock_glare = {
			title = { en = "Glare off the water" },
			text = { en = "The dock light's glare bounced off the water and hid the dock edge." },
		},
		skyglow_seen = {
			title = { en = "Skyglow through the telescope" },
			text = { en = "Through the telescope, light from town made the sky glow and hid the stars." },
		},
		timer_used = {
			title = { en = "Timers keep needed light" },
			text = { en = "A timer kept a light working when people need it, and off when they don't." },
		},
		echo_seen = {
			title = { en = "Fixes reach town" },
			text = { en = "Fixing a realm improved the matching lights back in Byers Station." },
		},
	},

	-- Moon clues for Act III. The game records these in each player's Star Journal as the
	-- story reveals them (ProgressionService). Plain in-game observations.
	Clues = {
		chime = {
			title = { en = "The Moon's chime" },
			text = { en = "Every time the Moon gave a tip, her chime had one wrong note." },
		},
		brighter = {
			title = { en = "The Moon keeps brightening" },
			text = { en = "After each realm we restored, the Moon shone a little brighter." },
		},
		red_glow = {
			title = { en = "The same red glow" },
			text = { en = "Every corrupted light had the same orange-red glow as the Moon's eye glint." },
		},
		guardian_Leo = {
			title = { en = "Leo's words" },
			text = { en = "Leo said someone kept feeding him glare." },
		},
		guardian_Orion = {
			title = { en = "Orion's words" },
			text = { en = "Orion said a pale voice told him to shine up, all night." },
		},
		guardian_Scorpius = {
			title = { en = "Scorpius's words" },
			text = { en = "Scorpius said the pale one called blue the only poison." },
		},
		guardian_Cetus = {
			title = { en = "Cetus's words" },
			text = { en = "Cetus said the one above wanted the pond to mirror only her." },
		},
	},

	Tips = {
		{
			id = "tip_broken_bulbs",
			lineId = "moon_tip_broken_bulbs",
			isMisleading = true,
			evidenceKey = "shield_cuts_glare",
			trigger = "rift",
			onDoubt = "moon_tip_broken_bulbs_doubt",
			onAgree = "moon_tip_broken_bulbs_agree",
			onTie = "moon_tip_broken_bulbs_tie",
		},
		{
			id = "tip_all_off",
			lineId = "moon_tip_all_off",
			isMisleading = true,
			evidenceKey = "crossing_needed",
			trigger = "afterRealm:Leo",
			onDoubt = "moon_tip_all_off_doubted",
			onAgree = "moon_tip_all_off_believed",
			onTie = "moon_tip_tie",
		},
		{
			id = "tip_orion",
			lineId = "moon_tip_orion",
			-- A true tip: players should not doubt everything the Moon says.
			isMisleading = false,
			evidenceKey = "orion_exit_needed",
			trigger = "afterRealm:Orion",
			onDoubt = "moon_tip_orion_doubt",
			onAgree = "moon_tip_orion_agree",
			onTie = "moon_tip_orion_tie",
		},
		{
			id = "tip_scorpius",
			lineId = "moon_tip_scorpius",
			isMisleading = true,
			evidenceKey = "spill_into_habitat",
			trigger = "afterRealm:Scorpius",
			onDoubt = "moon_tip_scorpius_doubt",
			onAgree = "moon_tip_scorpius_agree",
			onTie = "moon_tip_scorpius_tie",
		},
		{
			id = "tip_cetus",
			lineId = "moon_tip_cetus",
			isMisleading = true,
			evidenceKey = "dock_glare",
			trigger = "afterRealm:Cetus",
			onDoubt = "moon_tip_cetus_doubt",
			onAgree = "moon_tip_cetus_agree",
			onTie = "moon_tip_cetus_tie",
		},
		{
			id = "tip_timers",
			lineId = "moon_tip_timers",
			isMisleading = false,
			evidenceKey = "timer_used",
			trigger = "finale",
			onDoubt = "moon_tip_timers_doubt",
			onAgree = "moon_tip_timers_agree",
			onTie = "moon_tip_timers_tie",
		},
		{
			id = "tip_clouds",
			lineId = "moon_tip_clouds",
			isMisleading = true,
			evidenceKey = "skyglow_seen",
			trigger = "finale",
			onDoubt = "moon_tip_clouds_doubt",
			onAgree = "moon_tip_clouds_agree",
			onTie = "moon_tip_clouds_tie",
		},
		{
			id = "tip_brightest",
			lineId = "moon_tip_brightest",
			isMisleading = true,
			evidenceKey = "dock_glare",
			trigger = "finale",
			onDoubt = "moon_tip_brightest_doubt",
			onAgree = "moon_tip_brightest_agree",
			onTie = "moon_tip_brightest_tie",
		},
		{
			id = "tip_one_town",
			lineId = "moon_tip_one_town",
			isMisleading = false,
			evidenceKey = "echo_seen",
			trigger = "finale",
			onDoubt = "moon_tip_one_town_doubt",
			onAgree = "moon_tip_one_town_agree",
			onTie = "moon_tip_one_town_tie",
		},
	},
}

return MoonTipsConfig
