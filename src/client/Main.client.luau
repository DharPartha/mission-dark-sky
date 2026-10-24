--!strict
-- Main: starts the client controllers. Clients only present state and send requests;
-- the server owns progress, validation, and scoring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local SharedFolder = Root:WaitForChild("Shared")
local Net = require(SharedFolder:WaitForChild("Net"))
local Text = require(SharedFolder:WaitForChild("Text"))

local Controllers = script.Parent:WaitForChild("Controllers")
local UiKit = require(Controllers:WaitForChild("UiKit"))
local HUDController = require(Controllers:WaitForChild("HUDController"))
local BubbleRenderer = require(Controllers:WaitForChild("BubbleRenderer"))
local FixtureMenuController = require(Controllers:WaitForChild("FixtureMenuController"))
local LuxLensController = require(Controllers:WaitForChild("LuxLensController"))
local SkyFXController = require(Controllers:WaitForChild("SkyFXController"))
local MoonTipController = require(Controllers:WaitForChild("MoonTipController"))
local JournalController = require(Controllers:WaitForChild("JournalController"))
local QualityController = require(Controllers:WaitForChild("QualityController"))
local NavigationController = require(Controllers:WaitForChild("NavigationController"))
local BikeController = require(Controllers:WaitForChild("BikeController"))
local QuizController = require(Controllers:WaitForChild("QuizController"))
local PledgeController = require(Controllers:WaitForChild("PledgeController"))
local ReportController = require(Controllers:WaitForChild("ReportController"))
local InputController = require(Controllers:WaitForChild("InputController"))
local SettingsSync = require(Controllers:WaitForChild("SettingsSync"))
local PhaseMarkerController = require(Controllers:WaitForChild("PhaseMarkerController"))
local SplashController = require(Controllers:WaitForChild("SplashController"))
local SkyDomeController = require(Controllers:WaitForChild("SkyDomeController"))

local player = Players.LocalPlayer

-- Use the player's language when a translation exists (Text falls back to the default).
local localeOk, localeId = pcall(function()
	return string.sub(player.LocaleId, 1, 2)
end)
if localeOk and typeof(localeId) == "string" then
	Text.setLocale(localeId)
end

local stateFolder = Root:WaitForChild(Net.StateFolder) :: Folder
local remotesFolder = Net.waitForRemotes(Root)
local remotes: { [string]: RemoteEvent } = {}
for _, name in Net.Remotes do
	remotes[name] = remotesFolder:WaitForChild(name) :: RemoteEvent
end

local gui = Instance.new("ScreenGui")
gui.Name = "DarkSkyUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
UiKit.attachScreenScale(gui)

QualityController.init()
-- The splash goes up first so the player sees the night sky while everything else loads.
SplashController.init(stateFolder)
NavigationController.init(stateFolder)
HUDController.init(gui, stateFolder, remotesFolder)
JournalController.init(gui)
BubbleRenderer.init(gui, remotes.Dialogue)
FixtureMenuController.init(gui, stateFolder, remotes)
LuxLensController.init(stateFolder)
HUDController.setLensToggle(LuxLensController.toggle)
SkyFXController.init(stateFolder, remotes.GlareEvent, function(seconds: number, bannerKey: string)
	HUDController.showBanner(bannerKey, seconds)
	BubbleRenderer.pause(seconds)
end)
MoonTipController.init(gui, stateFolder, remotes)
BikeController.init(gui, remotes.BikeRequest)
QuizController.init(gui, stateFolder, remotes.QuizSubmit)
PledgeController.init(gui, stateFolder, remotes.PledgeSubmit)
ReportController.init(gui, remotes.ReportGenerated)
InputController.init({
	toggleLens = HUDController.toggleLens,
	requestHint = function()
		remotes.RequestHint:FireServer()
	end,
})
SettingsSync.init(remotes.SaveSettings)
PhaseMarkerController.init(stateFolder)
SkyDomeController.init(stateFolder)

-- Tell the server we are listening, so the intro dialogue is not missed.
remotes.ClientReady:FireServer()
