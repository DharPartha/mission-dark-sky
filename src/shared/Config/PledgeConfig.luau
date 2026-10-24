--!strict
-- PledgeConfig: the Night Sky Pledge. Players choose at least one safe action per place.
-- Every action is age-appropriate. Anything involving a light fixture or electricity is
-- framed as talking with a responsible adult; nothing asks children to climb, touch,
-- unscrew, rewire, or switch off essential lighting. Owner review required before release.

local PledgeConfig = {
	-- Display order of the places.
	Categories = { "Home", "School", "Community" },
	-- At most this many actions per place (keeps the Star Card short).
	MaxPerCategory = 3,
	Actions = {
		Home = {
			{ id = "home_ask_adult", text = { en = "Ask an adult if our outdoor lights could use a shield, timer, or warmer bulb." } },
			{ id = "home_curtains", text = { en = "Close curtains at night so indoor light stays inside." } },
			{ id = "home_unneeded_off", text = { en = "With an adult's OK, switch off a yard light nobody is using." } },
			{ id = "home_stargaze", text = { en = "Go stargazing with my family and count the stars we can see." } },
		},
		School = {
			{ id = "school_audit", text = { en = "Suggest an adult-led lighting check of our school grounds." } },
			{ id = "school_share", text = { en = "Share what I learned about responsible lighting with my class." } },
			{ id = "school_poster", text = { en = "Make a 'Make every light count' poster." } },
		},
		Community = {
			{ id = "community_report", text = { en = "With an adult, report a glaring light to the right local office." } },
			{ id = "community_starcount", text = { en = "Join or start a community star-counting night." } },
			{ id = "community_thanks", text = { en = "Thank neighbors who use shielded, warm, well-aimed lights." } },
		},
	},
}

return PledgeConfig
