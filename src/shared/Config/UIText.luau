--!strict
-- UIText: every player-facing interface string, by locale.
-- Use %d / %s placeholders where a number or word is inserted. Keep the same placeholders
-- in every translation. Values marked as readings are game estimates, not measurements.

local UIText = {
	Strings = {
		-- Identity
		title = { en = "The Dark Sky" },
		tagline = { en = "A shared world. A shared responsibility." },
		core_rule = { en = "Don't eliminate light. Make every light count." },
		zone_leo = { en = "Lantern Lane: Leo's Glare Gate" },
		boss_leo = { en = "Leo, the Blinded Lion" },
		sign_crossing = { en = "CROSSING LIGHT\nKeeps walkers safe at night" },

		-- Fixtures and need
		fixture_lamp_corner = { en = "Corner streetlight" },
		fixture_flood_garage = { en = "Garage floodlight" },
		fixture_crossing = { en = "Crosswalk light" },
		need_Required = { en = "Required: safety light" },
		need_Useful = { en = "Useful: people use it" },
		need_Unneeded = { en = "Not needed here" },
		need_unknown = { en = "Needed? Ask first" },

		-- Darkness Meter
		meter_label = { en = "Darkness Meter" },
		meter_value = { en = "%d / 100" },
		band_choked = { en = "Glare-choked" },
		band_hazy = { en = "Hazy" },
		band_clearing = { en = "Clearing" },
		band_starry = { en = "Starry" },
		band_pristine = { en = "Pristine" },
		estimate_note = { en = "Game estimates, not real measurements." },

		-- HUD buttons
		hud_lens = { en = "Lux Lens" },
		hud_lens_on = { en = "Lux Lens: ON" },
		hud_compare = { en = "Compare" },
		hud_settings = { en = "Settings" },

		-- Objectives
		objective_intro = { en = "Listen to your friends." },
		objective_investigate = { en = "Walk to a streetlight and inspect it." },
		objective_confront = { en = "Fix the glare. Reach %d on the Darkness Meter." },
		objective_restored = { en = "Leo is calm! Listen to the Moon." },
		objective_moontip = { en = "The Moon has a tip. Does it sound right?" },
		objective_complete = { en = "Leo's realm restored!" },
		objective_free_roam = { en = "All missions done. Explore Byers Station!" },
		mission_leo_slice = { en = "Leo's Glare Gate" },

		-- World prompts
		prompt_inspect = { en = "Inspect" },
		prompt_light = { en = "Light" },
		prompt_talk = { en = "Talk" },

		-- Fixture menu
		menu_readings = { en = "Lux Lens readings" },
		reading_brightness = { en = "Brightness" },
		reading_glare = { en = "Glare" },
		reading_uplight = { en = "Sky glow" },
		reading_color = { en = "Color" },
		reading_aim = { en = "Aim" },
		reading_schedule = { en = "Timer" },
		reading_shield = { en = "Shield" },
		reading_value_10 = { en = "%d / 10" },
		reading_percent = { en = "%d%%" },
		reading_kelvin = { en = "%dK" },
		verb_QUESTION = { en = "QUESTION" },
		verb_SHIELD = { en = "SHIELD" },
		verb_AIM = { en = "AIM" },
		verb_DIM = { en = "DIM" },
		verb_TIME = { en = "TIME" },
		verb_WARM = { en = "WARM" },
		btn_ask = { en = "Is it needed?" },
		btn_off = { en = "Turn off" },
		btn_shield_add = { en = "Add shield" },
		btn_shield_remove = { en = "Remove shield" },
		btn_aim_down = { en = "Aim lower" },
		btn_aim_up = { en = "Aim higher" },
		btn_dim_down = { en = "Dimmer" },
		btn_dim_up = { en = "Brighter" },
		btn_time_next = { en = "Change timer" },
		btn_warmer = { en = "Warmer" },
		btn_cooler = { en = "Cooler" },
		btn_undo = { en = "Undo" },
		btn_close = { en = "Close" },
		aim_Down = { en = "Down" },
		aim_Angled = { en = "Angled" },
		aim_Out = { en = "Outward" },
		aim_Up = { en = "Upward" },
		schedule_AllNight = { en = "On all night" },
		schedule_Motion = { en = "Motion sensor" },
		schedule_Curfew = { en = "Off late at night" },
		shield_yes = { en = "Yes" },
		shield_no = { en = "No" },
		status_off = { en = "Switched off" },

		-- Answers to "Is it needed?"
		question_useful_sidewalk = { en = "Needed: it lights the sidewalk. Fix how it shines." },
		question_useful_driveway = { en = "Needed: it lights the driveway, but it blasts the street." },
		question_required_crossing = { en = "Required: walkers cross here. Keep it on, but improve it." },

		-- Action results
		notice_shield_on = { en = "Shield added. Less light escapes sideways and up." },
		notice_shield_off = { en = "Shield removed." },
		notice_aim = { en = "Aim changed: %s." },
		notice_dim = { en = "Brightness now %d%%." },
		notice_time = { en = "Timer: %s." },
		notice_warm = { en = "Color now %dK." },
		notice_undo = { en = "Last change undone." },
		notice_nothing_to_undo = { en = "Nothing to undo on this light." },
		notice_off_ok = { en = "Switched off. It wasn't needed here." },

		-- Refusals (server explains every rejected action)
		notice_too_far = { en = "Move closer to the light." },
		notice_cooldown = { en = "One moment..." },
		notice_wait_intro = { en = "Wait for your friends to finish talking." },
		notice_verb_unavailable = { en = "That action isn't available for this light." },
		notice_dim_floor = { en = "That's as dim as this light should go." },
		notice_dim_floor_safety = { en = "Safety light: it can't go dimmer than this." },
		notice_dim_max = { en = "That's already full brightness." },
		notice_aim_limit = { en = "It can't aim any further that way." },
		notice_warm_limit = { en = "That's already the warmest setting." },
		notice_cool_limit = { en = "That's already the coolest setting." },
		notice_schedule_fixed = { en = "Safety light: it must stay on all night." },
		notice_schedule_single = { en = "This light has only one timer option." },
		notice_off_refused_required = { en = "Safety light! It must stay on. Improve it instead." },
		notice_off_refused_useful = { en = "People use this light. Improve it instead of switching it off." },
		notice_bad_request = { en = "That didn't work. Try again." },

		-- Encounter
		notice_evidence = { en = "Team evidence found: %s" },
		notice_telegraph = { en = "Leo is about to roar! Get out of the red glare zones." },
		notice_glare_hit = { en = "Glare! You're slowed for a moment. Find shadow." },
		notice_restored = { en = "Leo's realm restored! The stars return." },
		notice_token = { en = "You earned a Doubt Token!" },
		notice_no_token = { en = "No Doubt Token this time." },
		notice_reset = { en = "Realm reset for testing." },

		-- Before/after panel
		compare_title = { en = "Before and after" },
		compare_before = { en = "Before" },
		compare_now = { en = "Now" },
		compare_score = { en = "Darkness score" },
		compare_safe = { en = "Safe paths lit" },
		compare_blue = { en = "Blue light" },
		yes = { en = "Yes" },
		no = { en = "No" },

		-- Moon tip vote
		vote_title = { en = "The Moon's tip" },
		vote_agree = { en = "Sounds right" },
		vote_doubt = { en = "Doubt it!" },
		vote_evidence = { en = "Evidence you found" },
		vote_no_evidence = { en = "No evidence yet. What did the crossing sign say?" },
		vote_status = { en = "Votes: %d of %d. %d seconds left." },
		vote_cast = { en = "Your vote: %s" },

		-- Settings
		settings_title = { en = "Settings" },
		setting_reduced_motion = { en = "Reduced motion" },
		setting_large_text = { en = "Large text" },
		setting_high_contrast = { en = "High contrast" },
		setting_on = { en = "On" },
		setting_off = { en = "Off" },
		settings_version = { en = "Version %s" },
		quality_setting = { en = "Graphics: %s" },
		quality_Auto = { en = "Auto" },
		quality_Low = { en = "Low" },
		quality_Mid = { en = "Medium" },
		quality_High = { en = "High" },

		-- Star Journal (personal)
		hud_journal = { en = "Journal" },
		journal_title = { en = "Star Journal" },
		journal_subtitle = { en = "Your discoveries. Simulated game evidence." },
		journal_empty = { en = "Nothing yet. Inspect lights to collect evidence." },
		journal_section_realm = { en = "Realms restored" },
		journal_section_evidence = { en = "Evidence" },
		journal_section_moonTip = { en = "Moon claims checked" },
		journal_realm_entry = { en = "%s: Darkness %d before, %d after" },
		journal_tip_correct = { en = "Evidence-based call" },
		journal_tip_incorrect = { en = "Not this time. Check the evidence." },
		tokens_chip = { en = "Doubt Tokens: %d" },

		-- Save status (personal)
		save_loading = { en = "Loading your save..." },
		save_loaded = { en = "Progress saves automatically" },
		save_new = { en = "New save started" },
		save_memory = { en = "Test file: progress is not saved" },
		save_unsaved = { en = "Couldn't load your save. Playing without saving." },
		save_lock_lost = { en = "Your save opened on another server. Saving paused here." },

		-- Developer test tools (only shown to authorized developers)
		dev_banner = { en = "TEST MODE: %s" },
		dev_reset_world = { en = "Reset world (everyone here)" },
		dev_reset_profile = { en = "Reset MY save" },
		dev_confirm_hint = { en = "Type %s, then press a reset button" },
		notice_dev_denied = { en = "Test tools are not available here." },
		notice_dev_confirm = { en = "Type the confirm word first." },
		notice_profile_reset = { en = "Your save was reset (test)." },
	},
}

return UIText
