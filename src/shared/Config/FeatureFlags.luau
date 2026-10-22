--!strict
-- FeatureFlags: switch systems on or off without editing gameplay scripts.

local FeatureFlags = {
	-- Shows a "Reset realm" button. It only ever works inside Roblox Studio.
	EnableTestReset = true,
	-- Runs the pure-logic self tests when the server starts (Studio and live).
	RunSelfTestsOnStart = true,
	-- Leo's periodic roar that applies temporary Glare to players in glare zones.
	EnableLeoRoar = true,
	-- The Moon's "Doubt it!" tip after Leo is restored.
	EnableMoonTips = true,
	-- Firefly wildlife cue in the meadow (turned off automatically in reduced motion).
	EnableFireflies = true,
}

return FeatureFlags
