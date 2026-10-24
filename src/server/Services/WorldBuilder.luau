--!strict
-- WorldBuilder: builds the whole world at server start (placeholder art from Roblox parts)
-- by calling the builders in ServerScriptService.DarkSky.World, and returns handles other
-- services use. Inputs: WorldConfig, FixtureConfig, BossConfig. Outputs: World (below).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local Types = require(Root:WaitForChild("Shared"):WaitForChild("Types"))

local WorldFolder = script.Parent.Parent:WaitForChild("World")
local Parts = require(WorldFolder:WaitForChild("Parts"))
local FixtureBuilder = require(WorldFolder:WaitForChild("FixtureBuilder"))
local SkyBuilder = require(WorldFolder:WaitForChild("SkyBuilder"))
local NpcBuilder = require(WorldFolder:WaitForChild("NpcBuilder"))
local TownBuilder = require(WorldFolder:WaitForChild("TownBuilder"))
local GlarelandsBuilder = require(WorldFolder:WaitForChild("GlarelandsBuilder"))

local WorldBuilder = {}

export type FixtureParts = FixtureBuilder.FixtureParts
export type LeoParts = SkyBuilder.LeoParts
export type MoonParts = SkyBuilder.MoonParts

export type Rift = { part: BasePart, prompt: ProximityPrompt }

export type World = {
	folder: Folder,
	fixtures: { [string]: FixtureParts },
	friends: NpcBuilder.Friends,
	npcPrompts: { [string]: ProximityPrompt },
	leo: LeoParts,
	moons: { MoonParts },
	fireflies: ParticleEmitter,
	spawn: SpawnLocation,
	interactables: { [string]: ProximityPrompt },
	rifts: { town: Rift, glare: Rift },
}

-- Tags let other scripts find zones and fixtures without hard-coded paths.
WorldBuilder.Tags = { Zone = "DarkSkyZone", Fixture = FixtureBuilder.Tag, Npc = NpcBuilder.Tag }

function WorldBuilder.applyFixtureVisual(parts: FixtureParts, state: Types.FixtureState)
	FixtureBuilder.applyVisual(parts, state)
end

function WorldBuilder.placeCompanions(world: World, stationId: string)
	NpcBuilder.placeAt(world.friends, stationId)
end

local function setupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(38, 40, 58)
	Lighting.OutdoorAmbient = Color3.fromRGB(46, 48, 70)
	Lighting.EnvironmentDiffuseScale = 0.2
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.GlobalShadows = true

	-- Clear previous runs so Play-Stop-Play in Studio does not stack effects.
	for _, child in Lighting:GetChildren() do
		if child:GetAttribute("DarkSky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.Name = "DarkSkySky"
	-- Our Moon character replaces the default sun and moon.
	sky.CelestialBodiesShown = false
	sky.StarCount = Tuning.Sky.StarCountAt0
	sky:SetAttribute("DarkSky", true)
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "DarkSkyAtmosphere"
	atmosphere.Density = Tuning.Sky.AtmosphereDensityAt0
	atmosphere.Haze = Tuning.Sky.AtmosphereHazeAt0
	atmosphere.Glare = Tuning.Sky.AtmosphereGlareAt0
	atmosphere.Color = Tuning.Sky.AtmosphereColorAt0
	atmosphere.Decay = Color3.fromRGB(40, 36, 60)
	atmosphere:SetAttribute("DarkSky", true)
	atmosphere.Parent = Lighting

	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "DarkSkyTint"
	tint.TintColor = Tuning.Sky.TintAt0
	tint:SetAttribute("DarkSky", true)
	tint.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "DarkSkyBloom"
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom:SetAttribute("DarkSky", true)
	bloom.Parent = Lighting
end

function WorldBuilder.build(): World
	local existing = Workspace:FindFirstChild("DarkSkyWorld")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "DarkSkyWorld"
	folder.Parent = Workspace

	setupLighting()
	local town = TownBuilder.build(folder)
	local glarelands = GlarelandsBuilder.build(folder)

	local fixtures: { [string]: FixtureParts } = {}
	local glareMinX = WorldConfig.Regions.Glarelands.minX
	for zoneId, zone in FixtureConfig.Zones do
		local zoneModel = Parts.makeModel("Zone_" .. zoneId, folder)
		zoneModel:SetAttribute("ZoneId", zoneId)
		CollectionService:AddTag(zoneModel, WorldBuilder.Tags.Zone)
		for _, def in zone.fixtures do
			local palette = if def.position.X >= glareMinX then Parts.Glare else Parts.Town
			local parts = FixtureBuilder.build(def :: any, zoneModel, palette)
			FixtureBuilder.applyVisual(parts, def.initial :: any)
			fixtures[def.id] = parts
		end
	end

	local friends = NpcBuilder.build(folder, "hub")
	-- One Moon per region so she watches over both worlds.
	local offset = WorldConfig.GlarelandsOffset
	local moonCenter = Vector3.new(-140, 175, -230)
	local moons = {
		SkyBuilder.buildMoon(folder, moonCenter, Vector3.new(0, 20, 0)),
		SkyBuilder.buildMoon(folder, offset + moonCenter, offset + Vector3.new(0, 20, 0)),
	}

	return {
		folder = folder,
		fixtures = fixtures,
		friends = friends,
		npcPrompts = friends.prompts,
		leo = SkyBuilder.buildLeo(folder),
		moons = moons,
		fireflies = town.fireflies,
		spawn = town.spawn,
		interactables = { telescope = town.telescopePrompt },
		rifts = {
			town = { part = town.rift, prompt = town.riftPrompt },
			glare = { part = glarelands.rift, prompt = glarelands.riftPrompt },
		},
	}
end

return WorldBuilder
