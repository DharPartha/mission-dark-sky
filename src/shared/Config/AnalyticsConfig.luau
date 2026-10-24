--!strict
-- AnalyticsConfig: the only analytics events the game may send.
-- Events are anonymous and aggregate: an event name plus an optional number.
-- Never add names, chat, free text, locations, or other personal details.

local AnalyticsConfig = {
	-- Event name -> what it counts (documentation for reviewers).
	Events = {
		session_start = "A player joined",
		mission_step = "A team reached a mission step (value = step index)",
		mission_complete = "A team completed a mission",
		realm_restored = "A realm was restored (value = final score)",
		moon_tip_correct = "A team made the evidence-based call on a Moon tip",
		moon_tip_incorrect = "A team agreed with a misleading tip (or rejected a true one)",
		unsafe_action_refused = "Someone tried to switch off or over-dim a needed light",
		save_unavailable = "A profile could not be loaded and the player played unsaved",
		quiz_pre_score = "Pre-adventure check score (value = correct answers, 0-3)",
		auto_hint_shown = "A friend offered an automatic hint (value = seconds into the step)",
		hint_requested = "A player pressed the Hint button",
		finale_phase_complete = "A team finished a finale phase (value = phase number)",
		ending_reached = "A player reached the ending",
		pledge_made = "A player made the Night Sky Pledge (value = number of actions chosen)",
		quiz_post_score = "Post-adventure check score (value = correct answers, 0-3)",
		quiz_change = "Post minus pre score for a player who took both (value -3 to 3)",
		final_claim_correct = "A team made the evidence-based call on a finale claim",
		final_claim_incorrect = "A team missed a finale claim",
		report_generated = "A player created the copyable community report",
		evidence_found = "A team found an evidence item (value = team evidence count)",
	},
}

return AnalyticsConfig
