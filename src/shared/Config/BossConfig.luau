--!strict
-- BossConfig: constellation bosses. Milestone 1 contains Leo only.
--
-- starPoints are (u, v) grid positions of the constellation outline. They are drawn on a
-- flat sky panel facing the street: u runs sideways, v runs up. The shape follows the
-- traditional Leo stick figure (sickle head plus triangle body); the creature is original.

local BossConfig = {
	Leo = {
		nameKey = "boss_leo",
		zoneId = "Leo",
		-- Center of the constellation panel in the world, and studs per grid unit.
		-- In the Glarelands (offset 4000, 0, 0), east of Leo's Glare Gate street.
		panelCenter = Vector3.new(4230, 95, -10),
		gridScale = 7,
		starPoints = {
			Regulus = { u = 0, v = 0 },
			Eta = { u = 2, v = 4 },
			Algieba = { u = 3, v = 8 },
			Zeta = { u = 2, v = 11 },
			Mu = { u = 0, v = 12 },
			Epsilon = { u = -2, v = 10 },
			Zosma = { u = 14, v = 9 },
			Chertan = { u = 14, v = 4 },
			Denebola = { u = 22, v = 6 },
		},
		lines = {
			{ "Regulus", "Eta" },
			{ "Eta", "Algieba" },
			{ "Algieba", "Zeta" },
			{ "Zeta", "Mu" },
			{ "Mu", "Epsilon" },
			{ "Algieba", "Zosma" },
			{ "Zosma", "Denebola" },
			{ "Denebola", "Chertan" },
			{ "Chertan", "Regulus" },
			{ "Zosma", "Chertan" },
		},
		corruptedColor = Color3.fromRGB(255, 96, 54),
		restoredColor = Color3.fromRGB(200, 222, 255),

		-- Roar cycle during the Confront phase. Telegraph gives players time to reach shadow.
		roarIntervalSeconds = 14,
		telegraphSeconds = 3,

		-- Dialogue sequences (ids in DialogueConfig.Sequences).
		wakeSequence = "leo_wake",
		restoredSequence = "leo_restored",
	},
}

return BossConfig
