--!strict
-- FeatureFlags: switch systems on or off without editing gameplay scripts.

local FeatureFlags = {
	-- Developer test tools (world reset, profile reset). The server also requires a dev
	-- environment and an authorized user (see ServerScriptService DevConfig).
	EnableTestReset = true,
	-- Save progress with DataStores (falls back to memory-only in unpublished Studio files).
	EnablePersistence = true,
	-- Anonymous aggregate analytics events (AnalyticsConfig lists every allowed event).
	EnableAnalytics = true,
	-- Runs the pure-logic self tests when the server starts (Studio and live).
	RunSelfTestsOnStart = true,
	-- Leo's periodic roar that applies temporary Glare to players in glare zones.
	EnableLeoRoar = true,
	-- The Moon's "Doubt it!" tip after Leo is restored.
	EnableMoonTips = true,
	-- Bicycles (ride mode). When off, players walk everywhere.
	EnableBikes = true,
	-- Friends offer hints automatically when a step takes a while.
	EnableAutoHints = true,
	-- Firefly wildlife cue in the meadow (turned off automatically in reduced motion).
	EnableFireflies = true,
}

return FeatureFlags
