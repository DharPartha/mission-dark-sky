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
		-- Act I opening on Lantern Lane.
		intro_1 = {
			speaker = "Narrator",
			style = "narration",
			text = { en = "Maple Hollow at night. The streets glow, but the sky is almost empty." },
		},
		intro_2 = {
			speaker = "Aadi",
			style = "speech",
			text = { en = "Where did all the stars go? I used to count them from my porch." },
		},
		intro_3 = {
			speaker = "Aditya",
			style = "speech",
			text = { en = "Let's test it. Walk up to a light and inspect it." },
		},
		intro_4 = {
			speaker = "Adrika",
			style = "speech",
			text = { en = "Careful. Paths and crossings still need light to stay safe." },
		},
		intro_5 = {
			speaker = "Moon",
			style = "speech",
			text = { en = "Hello, little stargazers! I'm the Moon. Need a friendly helper?" },
		},

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
		intro = { "intro_1", "intro_2", "intro_3", "intro_4", "intro_5" },
		leo_wake = { "leo_wake_1", "leo_wake_2", "leo_wake_3", "leo_wake_4" },
		leo_restored = { "leo_restored_1", "leo_restored_2", "leo_restored_3", "leo_restored_4" },
		moon_tip_all_off_doubted = { "moon_tip_all_off_doubted_1", "moon_tip_all_off_doubted_2" },
		moon_tip_all_off_believed = { "moon_tip_all_off_believed_1", "moon_tip_all_off_believed_2" },
		moon_tip_tie = { "moon_tip_tie", "moon_tip_all_off_believed_2" },
		complete = { "complete_1", "complete_2" },
	},

	-- Friend hint line per quest phase. Phases without an entry fall back to "after".
	Hints = {
		Aadi = { Intro = "hint_aadi_investigate", Investigate = "hint_aadi_investigate", Confront = "hint_aadi_confront", after = "hint_aadi_after" },
		Aditya = { Intro = "hint_aditya_investigate", Investigate = "hint_aditya_investigate", Confront = "hint_aditya_confront", after = "hint_aditya_after" },
		Adrika = { Intro = "hint_adrika_investigate", Investigate = "hint_adrika_investigate", Confront = "hint_adrika_confront", after = "hint_adrika_after" },
	},
}

return DialogueConfig
