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
HUDController.init(gui, stateFolder, remotesFolder)
JournalController.init(gui)
BubbleRenderer.init(gui, remotes.Dialogue)
FixtureMenuController.init(gui, stateFolder, remotes)
LuxLensController.init(stateFolder)
HUDController.setLensToggle(LuxLensController.toggle)
SkyFXController.init(stateFolder, remotes.GlareEvent, function(seconds: number)
	HUDController.showBanner("notice_telegraph", seconds)
	BubbleRenderer.pause(seconds)
end)
MoonTipController.init(gui, stateFolder, remotes)

-- Tell the server we are listening, so the intro dialogue is not missed.
remotes.ClientReady:FireServer()
