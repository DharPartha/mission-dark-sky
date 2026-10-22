--!strict
-- Bootstrap: starts The Dark Sky on the server.
-- Order: validate config -> self tests -> build world -> state + remotes -> services ->
-- let characters spawn -> start the quest when the first client is ready.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The world is built at runtime; hold characters back so nobody spawns into empty space.
Players.CharacterAutoLoads = false

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local Services = script.Parent:WaitForChild("Services")

local ExperienceConfig = require(ConfigFolder:WaitForChild("ExperienceConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Net = require(SharedFolder:WaitForChild("Net"))
local ConfigValidator = require(SharedFolder:WaitForChild("ConfigValidator"))

local function log(message: string, ...: any)
	print("[DarkSky] " .. string.format(message, ...))
end

log("Starting %s %s", ExperienceConfig.Title, ExperienceConfig.Version)

-- 1. Config validation: readable messages for whoever edited the config.
local report = ConfigValidator.validate({
	ExperienceConfig = ExperienceConfig,
	UIText = require(ConfigFolder:WaitForChild("UIText")),
	MissionConfig = require(ConfigFolder:WaitForChild("MissionConfig")),
	AnalyticsConfig = require(ConfigFolder:WaitForChild("AnalyticsConfig")),
	DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig")),
	MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig")),
	FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig")),
	BossConfig = require(ConfigFolder:WaitForChild("BossConfig")),
	Tuning = require(ConfigFolder:WaitForChild("Tuning")),
})
for _, message in report.warnings do
	warn("[DarkSky] Config warning: " .. message)
end
for _, message in report.errors do
	warn("[DarkSky] CONFIG ERROR: " .. message)
end
log("Config check: %d errors, %d warnings", #report.errors, #report.warnings)

-- 2. Pure-logic self tests.
if FeatureFlags.RunSelfTestsOnStart then
	local SelfTests = require(script.Parent:WaitForChild("Tests"):WaitForChild("SelfTests"))
	local passed, failures = SelfTests.run()
	for _, failure in failures do
		warn("[DarkSky] SELF TEST FAILED: " .. failure)
	end
	log("Self tests: %d passed, %d failed", passed, #failures)
end

-- 3. World, state, and remotes.
local WorldBuilder = require(Services:WaitForChild("WorldBuilder"))
local WorldStateService = require(Services:WaitForChild("WorldStateService"))
local ProfileService = require(Services:WaitForChild("ProfileService"))
local DialogueService = require(Services:WaitForChild("DialogueService"))
local FixturePuzzleService = require(Services:WaitForChild("FixturePuzzleService"))
local BossAIService = require(Services:WaitForChild("BossAIService"))
local MoonTipService = require(Services:WaitForChild("MoonTipService"))
local ProgressionService = require(Services:WaitForChild("ProgressionService"))
local DevService = require(Services:WaitForChild("DevService"))
local RemoteGuard = require(Services:WaitForChild("RemoteGuard"))

-- Saves start loading as soon as players arrive, in parallel with world building.
ProfileService.init()

local world = WorldBuilder.build()
WorldStateService.init()

local oldRemotes = Root:FindFirstChild(Net.RemotesFolder)
if oldRemotes then
	oldRemotes:Destroy()
end
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = Net.RemotesFolder
local remotes: { [string]: RemoteEvent } = {}
for _, name in Net.Remotes do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	remotes[name] = remote
end
remotesFolder.Parent = Root

-- 4. Services.
DialogueService.init(remotes.Dialogue)
FixturePuzzleService.init(world, remotes)
BossAIService.init(world, remotes)
MoonTipService.init(remotes)
ProgressionService.init(world, remotes)
DevService.init(remotes)

-- 5. Characters can spawn now that the ground exists.
Players.CharacterAutoLoads = true
Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)
for _, player in Players:GetPlayers() do
	player:LoadCharacter()
end

-- 6. Start the story once a client is listening, so nobody misses the opening dialogue.
-- The first ready player is the host whose save picks the starting point.
RemoteGuard.connect(remotes.ClientReady, "ClientReady", function(player: Player)
	ProgressionService.startForHost(player)
end)

log("Byers Station ready: %d fixtures", (function()
	local count = 0
	for _ in world.fixtures do
		count += 1
	end
	return count
end)())
