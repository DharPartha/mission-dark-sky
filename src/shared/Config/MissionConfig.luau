--!strict
-- MissionConfig: the story as an ordered list of missions, each an ordered list of steps.
-- ProgressionService runs these; no story order is hard-coded in scripts.
--
-- Step kinds:
--   dialogue  play `sequence` (DialogueConfig.Sequences), then continue
--   inspect   continue when anyone inspects a fixture in `zoneId`
--   restore   wake boss `bossId` (optional `enterSequence`), continue when `zoneId` reaches
--             its restoreThreshold with safe paths lit; restores the realm for the team
--   moonTip   run the team vote for MoonTipsConfig tip `tipId`
--
-- Optional per step: locksFixtures (no fixture changes during this step) and hintPhase
-- (which DialogueConfig.Hints entry friends use; default comes from the kind).
--
-- Every step needs `id` (unique in its mission) and `objectiveKey` (UIText).
-- Progress is saved per player at each step (checkpoint) and per mission (completed).
-- zonesRestored lists realms this mission restores, so a returning player's world can be
-- rebuilt from their save.

local MissionConfig = {
	Missions = {
		{
			id = "leo_slice",
			titleKey = "mission_leo_slice",
			zonesRestored = { "Leo" },
			steps = {
				{
					id = "intro",
					kind = "dialogue",
					sequence = "intro",
					objectiveKey = "objective_intro",
					-- Players listen first; friends give opening hints.
					locksFixtures = true,
					hintPhase = "Intro",
				},
				{ id = "investigate", kind = "inspect", zoneId = "Leo", objectiveKey = "objective_investigate" },
				{
					id = "confront",
					kind = "restore",
					zoneId = "Leo",
					bossId = "Leo",
					enterSequence = "leo_wake",
					objectiveKey = "objective_confront",
				},
				{ id = "restored", kind = "dialogue", sequence = "leo_restored", objectiveKey = "objective_restored" },
				{ id = "moontip", kind = "moonTip", tipId = "tip_all_off", objectiveKey = "objective_moontip" },
				{ id = "wrapup", kind = "dialogue", sequence = "complete", objectiveKey = "objective_complete" },
			},
		},
	},
	-- Objective shown once every mission is complete.
	FreeRoamObjectiveKey = "objective_free_roam",
}

return MissionConfig
