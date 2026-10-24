--!strict
-- ExperienceConfig: top-level identity and locale settings.
-- Safe to edit without touching gameplay scripts.

local ExperienceConfig = {
	-- Launch title. Owner approval is required before changing it for release.
	Title = "The Dark Sky",
	-- Build label shown in the settings panel and test logs.
	Version = "0.9.0-rc1",
	-- Locale used when a player's locale has no translation.
	DefaultLocale = "en",
	-- Every locale listed here must have a translation for every text entry.
	-- The validator reports missing ones.
	SupportedLocales = { "en" },
	-- Companion website (GitHub Pages) where players paste their report to print a PDF.
	-- Leave "" until the site is deployed; never guess a URL. Must start with https://.
	CompanionSiteUrl = "",
	-- Splash artwork (assets/splash/dark-sky-splash.png). Upload it in Studio (Asset Manager →
	-- Bulk Import), then paste its id here, e.g. "rbxassetid://123456789". While "" the splash
	-- is drawn from UI shapes instead.
	SplashImageId = "",
	-- true when the artwork already shows the DARK SKY title: the sky shows first and the art
	-- fades in after the title delay. false: the art shows at once and the title is added on top.
	SplashImageHasTitle = true,
}

return ExperienceConfig
