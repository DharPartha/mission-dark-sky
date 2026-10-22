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
--   trigger       when the tip plays. Supported: "afterRealm:<ZoneId>"
--   onDoubt       DialogueConfig sequence played when the team picks "Doubt it!"
--   onAgree       DialogueConfig sequence played when the team picks "Sounds right"
--   onTie         sequence for a tied vote (the Moon pushes her answer; no token)
--
-- Baseline design has 10 tips (6 misleading, 4 true). Milestone 1 ships one.
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
	},

	Tips = {
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
	},
}

return MoonTipsConfig
