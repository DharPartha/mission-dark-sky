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
	},
}

return AnalyticsConfig
