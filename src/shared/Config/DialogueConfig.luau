--!strict
-- DialogueConfig: every spoken line, the order lines play in, and friend hints.
--
-- Rules (the validator checks them):
--   * Each line has a speaker from Speakers, a style, and text for every supported locale.
--   * Text is at most 90 characters, short and roughly grade-6 reading level.
--   * Styles: "speech", "shout" (taunts), "thought", "narration" (system/narrator).
-- Friends and the Moon are fictional characters. Lines are placeholders for owner review.

local DialogueConfig = {
	Speakers = {
		Narrator = { displayName = "", world = false },
		Aadi = { displayName = "Aadi", world = true },
		Aditya = { displayName = "Aditya", world = true },
		Adrika = { displayName = "Adrika", world = true },
		Moon = { displayName = "Moon", world = false },
		Leo = { displayName = "Leo", world = false },
	},

	Lines = {
		-- Act I: the Starlight Hub, Lantern Lane, and the covered bridge.
		opening_1 = { speaker = "Narrator", style = "narration", text = { en = "Byers Station. Sleepover night at the Starlight Hub, the friends' barn clubhouse." } },
		opening_2 = { speaker = "Aadi", style = "speech", text = { en = "Telescope's set up! Tonight we find Orion, Leo, all of them." } },
		opening_3 = { speaker = "Aditya", style = "speech", text = { en = "Weird. The sky is a bright orange-gray. Where are the stars?" } },
		opening_4 = { speaker = "Adrika", style = "speech", text = { en = "Let's look through the telescope first. Then we figure out why." } },
		skyview_1 = { speaker = "Narrator", style = "narration", text = { en = "Through the lens: a few faint stars, lost in a glowing haze." } },
		skyview_2 = { speaker = "Aditya", style = "speech", text = { en = "That glow is skyglow. Light from town is spilling up into the sky." } },
		skyview_3 = { speaker = "Adrika", style = "speech", text = { en = "But people still need light to walk safely. So which lights are the problem?" } },
		tools_1 = { speaker = "Aditya", style = "speech", text = { en = "Take this Lux Lens. It gives game estimates of glare, spill, and color." } },
		tools_2 = { speaker = "Aditya", style = "speech", text = { en = "And a Star Journal. We'll write down evidence, not guesses." } },
		tools_3 = { speaker = "Aadi", style = "speech", text = { en = "Lantern Lane is right outside. Let's inspect those three lights!" } },
		homefix_1 = { speaker = "Adrika", style = "speech", text = { en = "Remember: the crossing light stays on. We make it better, not darker." } },
		homedone_1 = { speaker = "Aadi", style = "speech", text = { en = "Look up! A few more stars already." } },
		homedone_2 = { speaker = "Adrika", style = "speech", text = { en = "Same street, still safe, much less glare. That's the goal." } },
		homedone_3 = { speaker = "Aadi", style = "shout", text = { en = "Something's glowing orange down by the creek. Grab your bikes!" } },
		rift_1 = { speaker = "Narrator", style = "narration", text = { en = "Inside the covered bridge, an orange-red light tears the air open." } },
		rift_2 = { speaker = "Moon", style = "speech", text = { en = "Yoo-hoo! Up here! Don't be scared. It's just some broken lights." } },
		rift_3 = { speaker = "Moon", style = "speech", text = { en = "Hop through the Rift. I'll guide you. I'm VERY helpful!" } },
		rift_4 = { speaker = "Adrika", style = "speech", text = { en = "A talking Moon. Okay. Let's be careful and check everything." } },
		arrival_1 = { speaker = "Narrator", style = "narration", text = { en = "The Glarelands: a mirror of Byers Station, choked with harsh beams and red haze." } },
		arrival_2 = { speaker = "Aditya", style = "speech", text = { en = "This street matches Lantern Lane, but every light is blasting." } },
		arrival_3 = { speaker = "Aadi", style = "speech", text = { en = "Let's inspect one. Same tools, same rules." } },

		-- Act I friend hints.
		hint_aadi_quiz = { speaker = "Aadi", style = "speech", text = { en = "Quick quiz first! It just shows what we know right now." } },
		hint_aadi_telescope = { speaker = "Aadi", style = "speech", text = { en = "The telescope is on the deck. Use it to look at the sky!" } },
		hint_aadi_homefix = { speaker = "Aadi", style = "speech", text = { en = "Turn on the Lux Lens. Red circles show where glare spills." } },
		hint_aadi_ride = { speaker = "Aadi", style = "speech", text = { en = "Hop on your bike! Follow the Creek Trail sign south to the bridge." } },
		hint_aadi_rift = { speaker = "Aadi", style = "speech", text = { en = "The glow is inside the covered bridge. Step into it!" } },
		hint_aditya_quiz = { speaker = "Aditya", style = "speech", text = { en = "Pick what you think is right. We'll check again at the end." } },
		hint_aditya_telescope = { speaker = "Aditya", style = "speech", text = { en = "Look through the telescope. I want to see what the sky shows." } },
		hint_aditya_homefix = { speaker = "Aditya", style = "speech", text = { en = "Shield and aim first. Then dim to just enough, and warm the color." } },
		hint_aditya_ride = { speaker = "Aditya", style = "speech", text = { en = "Ride with R. Shift boosts, Space brakes. Or tap the bike buttons." } },
		hint_aditya_rift = { speaker = "Aditya", style = "speech", text = { en = "Readings near the bridge are off the charts. Let's go see." } },
		hint_adrika_quiz = { speaker = "Adrika", style = "speech", text = { en = "Take your time. Starting out unsure is fine." } },
		hint_adrika_telescope = { speaker = "Adrika", style = "speech", text = { en = "First we look, then we decide. The telescope is on the deck." } },
		hint_adrika_homefix = { speaker = "Adrika", style = "speech", text = { en = "The crossing light stays on. Make it better, not darker." } },
		hint_adrika_ride = { speaker = "Adrika", style = "speech", text = { en = "Stay on the trail. The bridge is past the meadow." } },
		hint_adrika_rift = { speaker = "Adrika", style = "speech", text = { en = "Stay together. Remember what we learned on Lantern Lane." } },

		-- Leo wakes after the first inspection.
		leo_wake_1 = {
			speaker = "Narrator",
			style = "narration",
			text = { en = "The glare twists into a shape. A lion of burning stars looms over the lane!" },
		},
		leo_wake_2 = {
			speaker = "Leo",
			style = "shout",
			text = { en = "ROAR! This glare is MINE! It makes me strong!" },
		},
		leo_wake_3 = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "When Leo roars, step into shadow. The glare only lasts a moment." },
		},
		leo_wake_4 = {
			speaker = "Aditya",
			style = "speech",
			text = { en = "Shield, aim, dim, or warm the lights. Watch the Darkness Meter." },
		},

		-- Leo calmed.
		leo_restored_1 = {
			speaker = "Leo",
			style = "speech",
			text = { en = "The burning... it's fading. I can see the sky again." },
		},
		leo_restored_2 = {
			speaker = "Leo",
			style = "thought",
			text = { en = "I never wanted this glare. Someone kept feeding it to me..." },
		},
		leo_restored_3 = {
			speaker = "Aadi",
			style = "speech",
			text = { en = "Look! Stars are coming back over Lantern Lane!" },
		},
		leo_restored_4 = {
			speaker = "Moon",
			style = "speech",
			text = { en = "Wonderful work! Now listen closely. I have a tip for you..." },
		},

		-- Moon tips (see MoonTipsConfig) and their follow-ups.
		moon_tip_all_off = {
			speaker = "Moon",
			style = "speech",
			text = { en = "Just switch EVERY light off. Darkness is always best!" },
		},
		moon_tip_all_off_doubted_1 = {
			speaker = "Moon",
			style = "speech",
			text = { en = "Oh! Clever you. I was only... testing you. Ha ha." },
		},
		moon_tip_all_off_doubted_2 = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "Right. The crossing light keeps walkers safe. Fix lights, don't erase them." },
		},
		moon_tip_all_off_believed_1 = {
			speaker = "Moon",
			style = "speech",
			text = { en = "See? Easy! Just trust me." },
		},
		moon_tip_all_off_believed_2 = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "Wait. Remember the crossing sign? People need that light to cross." },
		},
		moon_tip_tie = {
			speaker = "Moon",
			style = "speech",
			text = { en = "Can't decide? Then I'll take that as a yes!" },
		},

		-- Slice wrap-up.
		complete_1 = {
			speaker = "Narrator",
			style = "narration",
			text = { en = "Leo's stars shine again. But more constellations are still missing..." },
		},
		complete_2 = {
			speaker = "Aditya",
			style = "thought",
			text = { en = "The Moon sounded so sure. Next time, let's check the evidence first." },
		},

		-- Friend hints (Talk prompt), chosen by quest phase.
		hint_aadi_investigate = {
			speaker = "Aadi",
			style = "speech",
			text = { en = "That corner light is so bright I can't see any stars. Let's check it." },
		},
		hint_aadi_confront = {
			speaker = "Aadi",
			style = "speech",
			text = { en = "Turn on the Lux Lens. Red circles are glare zones. Shadows are safe." },
		},
		hint_aadi_after = {
			speaker = "Aadi",
			style = "speech",
			text = { en = "We did it! Look east. You can see Leo's shape now." },
		},
		hint_aditya_investigate = {
			speaker = "Aditya",
			style = "speech",
			text = { en = "Inspect a light. The Lux Lens shows glare, color, and sky glow." },
		},
		hint_aditya_confront = {
			speaker = "Aditya",
			style = "speech",
			text = { en = "Shields and aiming down cut glare the most. Then dim and warm." },
		},
		hint_aditya_after = {
			speaker = "Aditya",
			style = "speech",
			text = { en = "Tap Compare to see the before and after numbers." },
		},
		hint_adrika_investigate = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "Ask if each light is needed before you change it." },
		},
		hint_adrika_confront = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "The crossing light must stay on. We can still make it better." },
		},
		hint_adrika_after = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "Good lighting isn't no lighting. It's light where we need it." },
		},
	},

	-- Ordered line ids played together.
	Sequences = {
		opening = { "opening_1", "opening_2", "opening_3", "opening_4" },
		telescope_view = { "skyview_1", "skyview_2", "skyview_3" },
		tools = { "tools_1", "tools_2", "tools_3" },
		home_fix = { "homefix_1" },
		home_done = { "homedone_1", "homedone_2", "homedone_3" },
		rift_open = { "rift_1", "rift_2", "rift_3", "rift_4" },
		glare_arrival = { "arrival_1", "arrival_2", "arrival_3" },
		leo_wake = { "leo_wake_1", "leo_wake_2", "leo_wake_3", "leo_wake_4" },
		leo_restored = { "leo_restored_1", "leo_restored_2", "leo_restored_3", "leo_restored_4" },
		moon_tip_all_off_doubted = { "moon_tip_all_off_doubted_1", "moon_tip_all_off_doubted_2" },
		moon_tip_all_off_believed = { "moon_tip_all_off_believed_1", "moon_tip_all_off_believed_2" },
		moon_tip_tie = { "moon_tip_tie", "moon_tip_all_off_believed_2" },
		complete = { "complete_1", "complete_2" },
	},

	-- Friend hint line per quest phase. Phases without an entry fall back to "after".
	Hints = {
		Aadi = {
			Quiz = "hint_aadi_quiz",
			Telescope = "hint_aadi_telescope",
			Investigate = "hint_aadi_investigate",
			HomeFix = "hint_aadi_homefix",
			Confront = "hint_aadi_confront",
			Ride = "hint_aadi_ride",
			Rift = "hint_aadi_rift",
			after = "hint_aadi_after",
		},
		Aditya = {
			Quiz = "hint_aditya_quiz",
			Telescope = "hint_aditya_telescope",
			Investigate = "hint_aditya_investigate",
			HomeFix = "hint_aditya_homefix",
			Confront = "hint_aditya_confront",
			Ride = "hint_aditya_ride",
			Rift = "hint_aditya_rift",
			after = "hint_aditya_after",
		},
		Adrika = {
			Quiz = "hint_adrika_quiz",
			Telescope = "hint_adrika_telescope",
			Investigate = "hint_adrika_investigate",
			HomeFix = "hint_adrika_homefix",
			Confront = "hint_adrika_confront",
			Ride = "hint_adrika_ride",
			Rift = "hint_adrika_rift",
			after = "hint_adrika_after",
		},
	},
}

return DialogueConfig
