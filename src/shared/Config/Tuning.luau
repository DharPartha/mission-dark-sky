--!strict
-- Tuning: game-balance numbers.
-- Every number here is a GAME ESTIMATE chosen for teaching and playability.
-- None of them are real-world measurements, lighting standards, or savings claims.

local Tuning = {
	Score = {
		-- How much each problem counts toward a fixture's harm (any positive numbers; they are normalized).
		Weights = {
			glare = 0.35,
			uplight = 0.25,
			overLight = 0.20,
			blueLight = 0.20,
		},
		-- Below 1 so a fully polluted zone still starts above zero on the meter.
		HarmScale = 0.85,
		-- Darkness Meter bands (0-100, higher = healthier night). Each band needs a UIText key.
		Bands = {
			{ min = 0, textKey = "band_choked" },
			{ min = 25, textKey = "band_hazy" },
			{ min = 50, textKey = "band_clearing" },
			{ min = 75, textKey = "band_starry" },
			{ min = 100, textKey = "band_pristine" },
		},
	},

	Fixture = {
		-- Brightness change per DIM press (0-1 scale).
		BrightnessStep = 0.1,
		-- A full-cutoff shield leaves this fraction of the glare.
		ShieldedGlareFactor = 0.2,
		-- Light an unshielded fixture sends sideways/up, before aiming.
		UnshieldedUplight = 0.5,
		-- Aim positions from most downward to most upward. AIM moves one step.
		AimOrder = { "Down", "Angled", "Out", "Up" },
		AimGlare = { Down = 0.35, Angled = 0.7, Out = 1.0, Up = 0.8 },
		AimUplight = { Down = 0.0, Angled = 0.1, Out = 0.3, Up = 1.0 },
		-- Head tilt from straight down, in degrees, used for visuals.
		AimTiltDegrees = { Down = 0, Angled = 30, Out = 65, Up = 120 },
		-- How far the bright pool shifts toward the facing direction (studs).
		AimPoolOffset = { Down = 0, Angled = 6, Out = 14, Up = 0 },
		-- Color temperatures WARM/COOL step through, warmest first. 2200K is amber.
		ColorTemps = { 2200, 2700, 3000, 4000, 5000 },
		-- Blue-light reading is 0 at or below WarmK and 1 at or above CoolK.
		WarmK = 2700,
		CoolK = 5000,
		-- Approximate on-screen color for each temperature (presentation only).
		ColorTempRGB = {
			[2200] = Color3.fromRGB(255, 168, 82),
			[2700] = Color3.fromRGB(255, 190, 122),
			[3000] = Color3.fromRGB(255, 206, 152),
			[4000] = Color3.fromRGB(255, 232, 210),
			[5000] = Color3.fromRGB(226, 238, 255),
		},
		-- Fraction of the night each schedule keeps the light on. TIME cycles in this order.
		ScheduleOrder = { "AllNight", "Motion", "Curfew" },
		ScheduleOnFraction = { AllNight = 1.0, Motion = 0.45, Curfew = 0.6 },
		-- Visual light strength at brightness 1.
		SpotBrightnessAtFull = 6,
		SpotRange = 60,
		GlowBrightnessAtFull = 3,
		GlowRangeAtFull = 26,
	},

	Interact = {
		-- ProximityPrompt reach (studs).
		PromptDistance = 12,
		-- Server allows a little more than the prompt to absorb movement lag.
		MaxActionDistance = 22,
		-- Client closes the fixture menu past this distance.
		MenuCloseDistance = 24,
		-- Minimum seconds between fixture actions per player.
		ActionCooldownSeconds = 0.25,
		-- How many undo steps each fixture remembers.
		UndoDepth = 10,
	},

	-- Rate limits per remote (token bucket): burst size and average requests per second.
	-- Requests over the limit are dropped quietly.
	Remotes = {
		FixtureAction = { burst = 8, perSecond = 4 },
		MoonVote = { burst = 4, perSecond = 1 },
		ClientReady = { burst = 2, perSecond = 0.1 },
		DevRequest = { burst = 3, perSecond = 0.5 },
		BikeRequest = { burst = 6, perSecond = 3 },
		QuizSubmit = { burst = 3, perSecond = 0.5 },
		RequestHint = { burst = 2, perSecond = 0.2 },
		Unstuck = { burst = 2, perSecond = 0.1 },
		PledgeSubmit = { burst = 3, perSecond = 0.2 },
		ReportGenerated = { burst = 3, perSecond = 0.2 },
		SaveSettings = { burst = 4, perSecond = 0.5 },
	},

	-- Bicycle ride mode (no physics bike: the character moves faster with a bike attached).
	Bike = {
		RideSpeed = 30,
		BoostSpeed = 46,
		BoostSeconds = 2,
		BoostCooldownSeconds = 5,
		-- Riders closer than this to any fixture are dismounted so puzzles are on foot.
		NoRideRadius = 26,
		-- Server sanity check: horizontal speed above this (studs/s) for a while is pulled back.
		MaxPlausibleSpeed = 70,
		BellCooldownSeconds = 1.5,
	},

	-- Boss fairness: solo players get slower attacks and longer warnings, so co-op is
	-- never required. Attack size scales with how polluted the zone still is.
	Bosses = {
		SoloIntervalMultiplier = 1.3,
		SoloExtraTelegraphSeconds = 0.8,
		-- Players further than this outside the arena are never targeted.
		ArenaMargin = 10,
	},

	-- Adaptive guidance: friends offer a hint if a step takes a while. Players who solve
	-- realms without automatic hints get them later next time (still always available
	-- with the Hint button).
	Guidance = {
		AutoHintBaseSeconds = 45,
		-- Extra delay per independent solve, capped.
		AutoHintPerSkillSeconds = 25,
		MaxSkillLevel = 3,
		-- Glowing guide beam over reach targets after this long.
		BeaconAfterSeconds = 60,
	},

	Glare = {
		-- Glare zone radius at glare 1.0 (studs). Zones below MinGlare are not drawn or applied.
		MaxRadius = 26,
		MinGlare = 0.15,
		-- Temporary Glare penalty: never damage, never a death screen.
		DurationSeconds = 4,
		SlowWalkSpeed = 9,
		NormalWalkSpeed = 16,
	},

	-- Client sky blend between score 0 (polluted) and 100 (restored).
	-- Client sky blend between score 0 (polluted) and 100 (restored).
	-- Always night: even a polluted zone keeps a dark sky with some stars and a visible Moon.
	-- Skyglow shows as fewer stars and a thin, dusky haze, never a bright orange wash-out.
	Sky = {
		StarCountAt0 = 1500,
		StarCountAt100 = 5000,
		-- Thin enough that the Moon and constellations (300-700 studs away) stay visible.
		AtmosphereDensityAt0 = 0.16,
		AtmosphereDensityAt100 = 0.08,
		AtmosphereHazeAt0 = 1.1,
		AtmosphereHazeAt100 = 0.0,
		AtmosphereGlareAt0 = 0.12,
		AtmosphereGlareAt100 = 0.0,
		AtmosphereColorAt0 = Color3.fromRGB(96, 74, 84),
		AtmosphereColorAt100 = Color3.fromRGB(34, 46, 92),
		AtmosphereDecay = Color3.fromRGB(14, 20, 48),
		TintAt0 = Color3.fromRGB(242, 234, 232),
		TintAt100 = Color3.fromRGB(222, 230, 255),
		-- Bloom stays low with a high threshold so lights glow without blowing out the sky.
		BloomIntensityAt0 = 0.35,
		BloomIntensityAt100 = 0.2,
		BloomThreshold = 2.2,
		-- Fixed night lighting (Lighting service).
		ClockTime = 0,
		Brightness = 0.8,
		ExposureCompensation = -0.15,
		Ambient = Color3.fromRGB(24, 28, 52),
		OutdoorAmbient = Color3.fromRGB(30, 36, 66),
		-- Glare hit: a soft, short wash on the player's screen only.
		GlareHitBrightness = 0.22,
		-- Fireflies appear from this score upward.
		FirefliesFromScore = 50,
		FireflyRateAt100 = 14,
		-- Seconds for the sky to ease toward a new score.
		BlendSeconds = 1.5,
	},

	-- Opening splash: deep-blue night, bright moon, twinkling stars, the story constellations.
	Splash = {
		TitleDelaySeconds = 2,
		-- The splash stays at least this long, and behind any knowledge check.
		MinimumSeconds = 4.5,
		FadeSeconds = 1.2,
		StarCount = 180,
		-- Twinkle is a slow fade in and out (never a flash).
		TwinkleMinSeconds = 1.4,
		TwinkleMaxSeconds = 3.6,
	},

	-- The four constellations shown in the town sky (faint until their realm is restored).
	TownSky = {
		Distance = 480,
		Height = 230,
		GridScale = 8,
		StarSize = 6,
		FaintTransparency = 0.72,
	},

	Moon = {
		-- The Moon grows subtly brighter after each restored realm (foreshadowing).
		BaseBrightness = 1.0,
		BrightnessPerRealm = 0.35,
		-- Seconds the red eye glint shows (one short glint, well under 3 flashes per second).
		GlintSeconds = 0.6,
		-- Seconds players get to vote on a Moon tip.
		VoteTimeoutSeconds = 30,
	},
}

return Tuning
