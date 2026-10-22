--!strict
-- ExperienceConfig: top-level identity and locale settings.
-- Safe to edit without touching gameplay scripts.

local ExperienceConfig = {
	-- Launch title. Owner approval is required before changing it for release.
	Title = "The Dark Sky",
	-- Build label shown in the settings panel and test logs.
	Version = "0.1.0-m1-leo-slice",
	-- Locale used when a player's locale has no translation.
	DefaultLocale = "en",
	-- Every locale listed here must have a translation for every text entry.
	-- The validator reports missing ones. Spanish ("es") is planned for Milestone 3.
	SupportedLocales = { "en" },
}

return ExperienceConfig
