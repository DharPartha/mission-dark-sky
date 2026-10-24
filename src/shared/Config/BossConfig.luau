--!strict
-- BossConfig: the four constellation guardians of the Glarelands.
--
-- Constellation drawing: starPoints are (u, v) grid positions of the traditional stick
-- figure (public-domain star patterns); the creatures themselves are original. The figure is
-- drawn on a flat sky panel at panelCenter, facing viewerPosition, gridScale studs per unit.
--
-- Attacks (never damage; a hit gives temporary Glare: slower walking + screen washout):
--   roar    after a telegraph, players inside fixture glare zones are dazzled (Leo)
--   sweep   a beam lane across the arena; leave the red lane before it fires (Orion)
--   strike  a red circle on each player in the arena; step out before it lands.
--           tracking = true: the circle follows you for most of the telegraph (Cetus)
-- Attack size shrinks as the zone's Darkness score rises, so fixing lights visibly helps.
-- Timing is gentler for solo players (Tuning.Bosses).

local GLARE = Vector3.new(4000, 0, 0)

local function glare(x: number, y: number, z: number): Vector3
	return GLARE + Vector3.new(x, y, z)
end

local BossConfig = {
	Leo = {
		nameKey = "boss_leo",
		zoneId = "Leo",
		panelCenter = glare(230, 95, -10),
		viewerPosition = glare(-150, 0, 0),
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
		-- Glaring eyes sit near this star (the head).
		eyeStar = "Algieba",
		corruptedColor = Color3.fromRGB(255, 96, 54),
		restoredColor = Color3.fromRGB(200, 222, 255),
		arenaCenter = glare(0, 0, 0),
		arenaRadius = 130,
		attack = { kind = "roar", intervalSeconds = 14, telegraphSeconds = 3 },
		telegraphKey = "notice_telegraph",
		wakeSequence = "leo_wake",
		restoredSequence = "leo_restored",
	},

	Orion = {
		nameKey = "boss_orion",
		zoneId = "Orion",
		panelCenter = glare(-50, 105, 330),
		viewerPosition = glare(-50, 0, 165),
		gridScale = 9,
		starPoints = {
			Meissa = { u = 4, v = 13 },
			Betelgeuse = { u = 0, v = 10 },
			Bellatrix = { u = 8, v = 9 },
			Alnitak = { u = 3, v = 5 },
			Alnilam = { u = 4, v = 5.4 },
			Mintaka = { u = 5, v = 5.8 },
			Saiph = { u = 1, v = 0 },
			Rigel = { u = 9, v = 1 },
		},
		lines = {
			{ "Meissa", "Betelgeuse" },
			{ "Meissa", "Bellatrix" },
			{ "Betelgeuse", "Alnitak" },
			{ "Bellatrix", "Mintaka" },
			{ "Alnitak", "Alnilam" },
			{ "Alnilam", "Mintaka" },
			{ "Alnitak", "Saiph" },
			{ "Mintaka", "Rigel" },
		},
		eyeStar = "Meissa",
		corruptedColor = Color3.fromRGB(255, 120, 60),
		restoredColor = Color3.fromRGB(205, 220, 255),
		arenaCenter = glare(-50, 0, 165),
		arenaRadius = 95,
		attack = { kind = "sweep", intervalSeconds = 12, telegraphSeconds = 3, minWidth = 6, maxWidth = 22 },
		telegraphKey = "notice_telegraph_orion",
		wakeSequence = "orion_wake",
		restoredSequence = "orion_restored",
	},

	Scorpius = {
		nameKey = "boss_scorpius",
		zoneId = "Scorpius",
		panelCenter = glare(-80, 90, -430),
		viewerPosition = glare(-80, 0, -255),
		gridScale = 7,
		starPoints = {
			Acrab = { u = -1, v = 12 },
			Dschubba = { u = 0, v = 11 },
			Pi = { u = 1, v = 10 },
			Antares = { u = 2, v = 8 },
			Tau = { u = 3, v = 6.5 },
			Epsilon = { u = 4, v = 5 },
			Mu = { u = 4.5, v = 3.5 },
			ZetaSco = { u = 5, v = 2 },
			EtaSco = { u = 6, v = 0.5 },
			Theta = { u = 8, v = 0 },
			Iota = { u = 9.5, v = 1 },
			Kappa = { u = 10, v = 2.5 },
			Shaula = { u = 11, v = 3.5 },
		},
		lines = {
			{ "Acrab", "Dschubba" },
			{ "Dschubba", "Pi" },
			{ "Dschubba", "Antares" },
			{ "Antares", "Tau" },
			{ "Tau", "Epsilon" },
			{ "Epsilon", "Mu" },
			{ "Mu", "ZetaSco" },
			{ "ZetaSco", "EtaSco" },
			{ "EtaSco", "Theta" },
			{ "Theta", "Iota" },
			{ "Iota", "Kappa" },
			{ "Kappa", "Shaula" },
		},
		eyeStar = "Dschubba",
		corruptedColor = Color3.fromRGB(150, 190, 255),
		restoredColor = Color3.fromRGB(255, 214, 170),
		arenaCenter = glare(-80, 0, -260),
		arenaRadius = 100,
		attack = { kind = "strike", intervalSeconds = 10, telegraphSeconds = 2.6, minRadius = 5, maxRadius = 14, tracking = false },
		telegraphKey = "notice_telegraph_scorpius",
		wakeSequence = "scorpius_wake",
		restoredSequence = "scorpius_restored",
	},

	Cetus = {
		nameKey = "boss_cetus",
		zoneId = "Cetus",
		panelCenter = glare(390, 90, -150),
		viewerPosition = glare(210, 0, -150),
		gridScale = 7,
		starPoints = {
			Menkar = { u = 10, v = 8 },
			Kaffaljidhma = { u = 9, v = 10 },
			Xi = { u = 11, v = 11 },
			Lambda = { u = 12, v = 9.5 },
			Mira = { u = 7, v = 6 },
			ZetaCet = { u = 4, v = 5 },
			TauCet = { u = 2, v = 3 },
			Diphda = { u = 0, v = 2 },
			IotaCet = { u = 1, v = 6 },
			EtaCet = { u = 3, v = 7.5 },
			ThetaCet = { u = 5, v = 7 },
		},
		lines = {
			{ "Menkar", "Kaffaljidhma" },
			{ "Kaffaljidhma", "Xi" },
			{ "Xi", "Lambda" },
			{ "Lambda", "Menkar" },
			{ "Menkar", "Mira" },
			{ "Mira", "ZetaCet" },
			{ "ZetaCet", "TauCet" },
			{ "TauCet", "Diphda" },
			{ "Diphda", "IotaCet" },
			{ "IotaCet", "EtaCet" },
			{ "EtaCet", "ThetaCet" },
			{ "ThetaCet", "ZetaCet" },
		},
		eyeStar = "Kaffaljidhma",
		corruptedColor = Color3.fromRGB(255, 80, 90),
		restoredColor = Color3.fromRGB(190, 230, 255),
		arenaCenter = glare(210, 0, -150),
		arenaRadius = 95,
		attack = { kind = "strike", intervalSeconds = 11, telegraphSeconds = 3, minRadius = 6, maxRadius = 15, tracking = true },
		telegraphKey = "notice_telegraph_cetus",
		wakeSequence = "cetus_wake",
		restoredSequence = "cetus_restored",
	},
}

return BossConfig
