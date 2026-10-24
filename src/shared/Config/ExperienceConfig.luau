--!strict
-- ExperienceConfig: top-level identity and locale settings.
-- Safe to edit without touching gameplay scripts.

local ExperienceConfig = {
	-- Launch title. Owner approval is required before changing it for release.
	Title = "The Dark Sky",
	-- Build label shown in the settings panel and test logs.
	Version = "0.6.0-stage-f",
	-- Locale used when a player's locale has no translation.
	DefaultLocale = "en",
	-- Every locale listed here must have a translation for every text entry.
	-- The validator reports missing ones.
	SupportedLocales = { "en" },
	-- Companion website (GitHub Pages) where players paste their report to print a PDF.
	-- Leave "" until the site is deployed; never guess a URL. Must start with https://.
	CompanionSiteUrl = "",
}

return ExperienceConfig
