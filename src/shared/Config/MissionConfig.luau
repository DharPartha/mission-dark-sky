--!strict
-- MissionConfig: the story as an ordered list of missions, each an ordered list of steps.
-- ProgressionService runs these; no story order is hard-coded in scripts.
--
-- Step kinds:
--   dialogue  play `sequence` (DialogueConfig.Sequences), then continue
--   quiz      personal knowledge check `quizId` (QuizConfig); continues when everyone here
--             has answered (players who answered before are skipped) or the timer ends
--   interact  continue when anyone uses WorldConfig.Interactables[`targetId`]
--   grant     give everyone here the `unlocks` (e.g. luxLens, journal, bike), optionally
--             while playing `sequence`
--   inspect   continue when anyone inspects a fixture in `zoneId`
--   restore   continue when `zoneId` reaches its restoreThreshold with safe paths lit;
--             optional boss `bossId` wakes (with `enterSequence`) and is calmed
--   reach     continue when anyone reaches WorldConfig.Triggers[`targetId`]
--   moonTip   run the team vote for MoonTipsConfig tip `tipId`
--
-- Optional per step:
--   locksFixtures  no fixture changes during this step
--   hintPhase      which DialogueConfig.Hints entry friends use (default comes from the kind)
--   companions     WorldConfig.CompanionStations id the friends walk to
--   activeZone     zone shown on the Darkness Meter (inspect/restore steps set it automatically)
--   opensRift      opens the covered-bridge Rift for good once this step starts
--
-- Every step needs `id` (unique in its mission) and `objectiveKey` (UIText).
-- Saved checkpoints store step ids, so steps can be reordered without breaking saves.
-- zonesRestored lists zones a finished mission restores, to rebuild a returning player's world.

local MissionConfig = {
	Missions = {
		{
			id = "act1",
			titleKey = "mission_act1",
			zonesRestored = { "Home" },
			steps = {
				{ id = "precheck", kind = "quiz", quizId = "pre", objectiveKey = "objective_quiz", companions = "hub", locksFixtures = true, hintPhase = "Quiz", activeZone = "Home" },
				{ id = "opening", kind = "dialogue", sequence = "opening", objectiveKey = "objective_opening", locksFixtures = true, hintPhase = "Telescope" },
				{ id = "telescope", kind = "interact", targetId = "telescope", objectiveKey = "objective_telescope", locksFixtures = true, hintPhase = "Telescope" },
				{ id = "skyview", kind = "dialogue", sequence = "telescope_view", objectiveKey = "objective_opening", locksFixtures = true, hintPhase = "Telescope" },
				{ id = "tools", kind = "grant", unlocks = { "luxLens", "journal" }, sequence = "tools", objectiveKey = "objective_tools", companions = "lane", locksFixtures = true, hintPhase = "Investigate" },
				{ id = "home_inspect", kind = "inspect", zoneId = "Home", objectiveKey = "objective_home_inspect" },
				{ id = "home_fix", kind = "restore", zoneId = "Home", enterSequence = "home_fix", objectiveKey = "objective_home_fix", hintPhase = "HomeFix" },
				{ id = "bikes", kind = "grant", unlocks = { "bike" }, sequence = "home_done", objectiveKey = "objective_bike", hintPhase = "Ride" },
				{ id = "ride", kind = "reach", targetId = "bridge", objectiveKey = "objective_ride", companions = "bridge", hintPhase = "Ride" },
				{ id = "rift", kind = "dialogue", sequence = "rift_open", objectiveKey = "objective_rift_open", opensRift = true, hintPhase = "Rift" },
				{ id = "enter", kind = "reach", targetId = "glare_arrival", objectiveKey = "objective_enter_rift", hintPhase = "Rift" },
			},
		},
		{
			id = "leo",
			titleKey = "mission_leo",
			zonesRestored = { "Leo" },
			steps = {
				{ id = "arrival", kind = "dialogue", sequence = "glare_arrival", objectiveKey = "objective_glare_arrival", companions = "glare_leo", activeZone = "Leo", locksFixtures = true, hintPhase = "Investigate" },
				{ id = "investigate", kind = "inspect", zoneId = "Leo", objectiveKey = "objective_investigate" },
				{ id = "confront", kind = "restore", zoneId = "Leo", bossId = "Leo", enterSequence = "leo_wake", objectiveKey = "objective_confront" },
				{ id = "restored", kind = "dialogue", sequence = "leo_restored", objectiveKey = "objective_restored" },
				{ id = "moontip", kind = "moonTip", tipId = "tip_all_off", objectiveKey = "objective_moontip" },
				{ id = "wrapup", kind = "dialogue", sequence = "complete", objectiveKey = "objective_complete" },
			},
		},
	},
	-- Objective shown once every mission is complete.
	FreeRoamObjectiveKey = "objective_free_roam",
	-- Seconds a quiz step waits for answers before moving on anyway (never hard-lock).
	QuizTimeoutSeconds = 150,
}

return MissionConfig
