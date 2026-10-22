--!strict
-- DevConfig: server-only settings for environments and developer test tools.
-- Lives in ServerScriptService, so clients can never read or change it.
--
-- Environment is decided from game.PlaceId:
--   "local"       unpublished Studio file (PlaceId 0): memory-only saves, test tools allowed
--   "dev"         a PlaceId listed in DevPlaceIds: real DataStore (dev scope), test tools for DevUserIds
--   "production"  anything else: real DataStore, test tools always disabled
-- Unknown places count as production on purpose, so test tools fail closed.

local DevConfig = {
	-- PlaceIds of the private development experience. Fill in after publishing it.
	DevPlaceIds = {} :: { number },
	-- Roblox user ids allowed to use test tools in the dev experience.
	DevUserIds = {} :: { number },

	-- DataStore name and per-environment scope. Bump the name only with a migration plan.
	DataStoreName = "DarkSkyProfiles",
	DataScopes = {
		dev = "dev",
		production = "prod",
	},

	-- Persistence timing.
	AutosaveSeconds = 90,
	-- Checkpoint saves closer together than this are merged into one write.
	MinSecondsBetweenSaves = 20,
	-- A lock not refreshed for this long belongs to a crashed server.
	StaleLockSeconds = 300,
	MaxAttempts = 4,
	BaseBackoffSeconds = 1,

	-- Text a developer must type to confirm a reset.
	ResetConfirmWord = "RESET",
}

return DevConfig
