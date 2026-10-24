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
		{
			id = "orion",
			titleKey = "mission_orion",
			zonesRestored = { "Orion" },
			steps = {
				{ id = "travel", kind = "reach", targetId = "orion_gate", objectiveKey = "objective_go_orion", companions = "glare_orion", hintPhase = "Travel" },
				{ id = "arrival", kind = "dialogue", sequence = "orion_arrival", objectiveKey = "objective_glare_arrival", activeZone = "Orion", locksFixtures = true, hintPhase = "OrionFix" },
				{ id = "investigate", kind = "inspect", zoneId = "Orion", objectiveKey = "objective_realm_inspect", hintPhase = "OrionFix" },
				{ id = "confront", kind = "restore", zoneId = "Orion", bossId = "Orion", enterSequence = "orion_wake", objectiveKey = "objective_realm_fix", hintPhase = "OrionFix" },
				{ id = "restored", kind = "dialogue", sequence = "orion_restored", objectiveKey = "objective_restored" },
				{ id = "moontip", kind = "moonTip", tipId = "tip_orion", objectiveKey = "objective_realm_tip" },
				{ id = "wrapup", kind = "dialogue", sequence = "realm_done", objectiveKey = "objective_restored" },
			},
		},
		{
			id = "scorpius",
			titleKey = "mission_scorpius",
			zonesRestored = { "Scorpius" },
			steps = {
				{ id = "travel", kind = "reach", targetId = "scorpius_gate", objectiveKey = "objective_go_scorpius", companions = "glare_scorpius", hintPhase = "Travel" },
				{ id = "arrival", kind = "dialogue", sequence = "scorpius_arrival", objectiveKey = "objective_glare_arrival", activeZone = "Scorpius", locksFixtures = true, hintPhase = "ScorpiusFix" },
				{ id = "investigate", kind = "inspect", zoneId = "Scorpius", objectiveKey = "objective_realm_inspect", hintPhase = "ScorpiusFix" },
				{ id = "confront", kind = "restore", zoneId = "Scorpius", bossId = "Scorpius", enterSequence = "scorpius_wake", objectiveKey = "objective_realm_fix", hintPhase = "ScorpiusFix" },
				{ id = "restored", kind = "dialogue", sequence = "scorpius_restored", objectiveKey = "objective_restored" },
				{ id = "moontip", kind = "moonTip", tipId = "tip_scorpius", objectiveKey = "objective_realm_tip" },
				{ id = "wrapup", kind = "dialogue", sequence = "realm_done", objectiveKey = "objective_restored" },
			},
		},
		{
			id = "cetus",
			titleKey = "mission_cetus",
			zonesRestored = { "Cetus" },
			steps = {
				{ id = "travel", kind = "reach", targetId = "cetus_gate", objectiveKey = "objective_go_cetus", companions = "glare_cetus", hintPhase = "Travel" },
				{ id = "arrival", kind = "dialogue", sequence = "cetus_arrival", objectiveKey = "objective_glare_arrival", activeZone = "Cetus", locksFixtures = true, hintPhase = "CetusFix" },
				{ id = "investigate", kind = "inspect", zoneId = "Cetus", objectiveKey = "objective_realm_inspect", hintPhase = "CetusFix" },
				{ id = "confront", kind = "restore", zoneId = "Cetus", bossId = "Cetus", enterSequence = "cetus_wake", objectiveKey = "objective_realm_fix", hintPhase = "CetusFix" },
				{ id = "restored", kind = "dialogue", sequence = "cetus_restored", objectiveKey = "objective_restored" },
				{ id = "moontip", kind = "moonTip", tipId = "tip_cetus", objectiveKey = "objective_realm_tip" },
				{ id = "wrapup", kind = "dialogue", sequence = "realm_done", objectiveKey = "objective_restored" },
			},
		},
	},
	-- Objective shown once every mission is complete.
	FreeRoamObjectiveKey = "objective_free_roam",
	-- Seconds a quiz step waits for answers before moving on anyway (never hard-lock).
	QuizTimeoutSeconds = 150,
}

return MissionConfig
