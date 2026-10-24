--!strict
-- BossService: runs the constellation guardians (Leo, Orion, Scorpius, Cetus) from
-- BossConfig. While an encounter is active the guardian attacks on a cycle:
-- telegraph (banner + caption + ground marker) -> attack -> temporary Glare for anyone hit.
-- Puzzles, not damage, win the fight: the realm is restored by fixing its lights.
--
-- Fairness: attack size shrinks as the zone's Darkness score rises; solo players get
-- slower cycles and longer warnings (Tuning.Bosses), so co-op is never required.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DarknessMath = require(Root:WaitForChild("Shared"):WaitForChild("DarknessMath"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local GlareService = require(script.Parent:WaitForChild("GlareService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BossesFolder = script.Parent.Parent:WaitForChild("Bosses")
local AttackFx = require(BossesFolder:WaitForChild("AttackFx"))
local ATTACKS: { [string]: (AttackFx.Context) -> () } = {
	roar = require(BossesFolder:WaitForChild("Roar")),
	sweep = require(BossesFolder:WaitForChild("Sweep")),
	strike = require(BossesFolder:WaitForChild("Strike")),
}

local BossService = {}

-- Players this far beyond the arena edge still see the warning banner.
local BANNER_MARGIN = 60

local world: WorldBuilder.World
local glareEvent: RemoteEvent
local fxFolder: Folder
-- Bumped per boss on every start/stop so old loops notice they are stale and exit.
local generations: { [string]: number } = {}

local function config(bossId: string): { [string]: any }
	return (BossConfig :: any)[bossId]
end

local function setColor(bossId: string, color: Color3, beamTransparency: number)
	local parts = world.constellations[bossId]
	if parts == nil then
		return
	end
	for _, star in parts.stars do
		star.Color = color
	end
	for _, beam in parts.beams do
		beam.Color = ColorSequence.new(color)
		beam.Transparency = NumberSequence.new(beamTransparency)
	end
end

local function playersNear(boss: { [string]: any }, margin: number): { Player }
	local result = {}
	for _, player in Players:GetPlayers() do
		local rootPart = AttackFx.rootOf(player)
		if rootPart and AttackFx.flatDistance(rootPart.Position, boss.arenaCenter) <= boss.arenaRadius + margin then
			table.insert(result, player)
		end
	end
	return result
end

local function glareZones(zoneId: string): { { x: number, z: number, radius: number } }
	local zones = {}
	for fixtureId, state in WorldStateService.getZoneStates(zoneId) do
		local def = WorldStateService.getDefinition(fixtureId)
		local zone = if def then DarknessMath.glareZone(def, state) else nil
		if zone then
			table.insert(zones, zone)
		end
	end
	return zones
end

-- The best Doubt Token count among players here (tokens are personal; any one helps).
function BossService.teamTokens(): number
	local best = 0
	for _, player in Players:GetPlayers() do
		local profile = ProfileService.getProfile(player)
		if profile then
			best = math.max(best, profile.doubtTokens)
		end
	end
	return best
end

local function encounterLoop(bossId: string, myGeneration: number)
	local boss = config(bossId)
	local attack = ATTACKS[boss.attack.kind]
	local function stale(): boolean
		return generations[bossId] ~= myGeneration
	end
	while not stale() do
		local present = playersNear(boss, Tuning.Bosses.ArenaMargin)
		local solo = #Players:GetPlayers() <= 1
		local interval = boss.attack.intervalSeconds * (if solo then Tuning.Bosses.SoloIntervalMultiplier else 1)
		local telegraph = boss.attack.telegraphSeconds + (if solo then Tuning.Bosses.SoloExtraTelegraphSeconds else 0)
		task.wait(math.max(1, interval - telegraph))
		if stale() then
			return
		end
		present = playersNear(boss, Tuning.Bosses.ArenaMargin)
		if #present > 0 and attack then
			local score = WorldStateService.getAttribute(boss.zoneId .. "Score") or 0
			local intensity = math.clamp((100 - score) / 80, 0.2, 1)
			-- Doubt Tokens weaken the boss (optional help; never required to win).
			if boss.tokenWeakening then
				intensity *= math.max(0.4, 1 - BossService.teamTokens() * boss.tokenWeakening)
			end
			-- Warn everyone nearby: banner + the guardian flares (steady color change).
			for _, player in playersNear(boss, BANNER_MARGIN) do
				glareEvent:FireClient(player, "telegraph", telegraph, boss.telegraphKey)
			end
			setColor(bossId, Color3.fromRGB(255, 210, 140), 0)
			attack({
				boss = boss,
				intensity = intensity,
				telegraphSeconds = telegraph,
				playersInArena = function()
					return playersNear(boss, Tuning.Bosses.ArenaMargin)
				end,
				glareZones = function()
					return glareZones(boss.zoneId)
				end,
				glare = GlareService.apply,
				isStale = stale,
				folder = fxFolder,
			})
			if not stale() then
				setColor(bossId, boss.corruptedColor, 0.3)
			end
		end
	end
end

function BossService.init(builtWorld: WorldBuilder.World, remotes: { [string]: RemoteEvent })
	world = builtWorld
	glareEvent = remotes.GlareEvent
	local existing = Workspace:FindFirstChild("DarkSkyBossFX")
	if existing then
		existing:Destroy()
	end
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "DarkSkyBossFX"
	fxFolder.Parent = Workspace
end

function BossService.setCorrupted(bossId: string)
	generations[bossId] = (generations[bossId] or 0) + 1
	local boss = config(bossId)
	setColor(bossId, boss.corruptedColor, 0.3)
	for _, eye in world.constellations[bossId].eyes do
		eye.Transparency = 0
	end
end

function BossService.setAllCorrupted()
	for bossId in BossConfig do
		BossService.setCorrupted(bossId)
	end
	GlareService.clearAll()
end

function BossService.startEncounter(bossId: string)
	generations[bossId] = (generations[bossId] or 0) + 1
	if FeatureFlags.EnableLeoRoar then
		task.spawn(encounterLoop, bossId, generations[bossId])
	end
end

-- Pauses a guardian's attacks without calming it (finale votes and dialogue).
function BossService.stopEncounter(bossId: string)
	generations[bossId] = (generations[bossId] or 0) + 1
	setColor(bossId, config(bossId).corruptedColor, 0.3)
end

-- Calms a guardian: stops attacks, clears Glare, and fades its stars to their true color.
function BossService.restore(bossId: string)
	generations[bossId] = (generations[bossId] or 0) + 1
	GlareService.clearAll()
	local boss = config(bossId)
	local parts = world.constellations[bossId]
	local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	for _, star in parts.stars do
		TweenService:Create(star, tweenInfo, { Color = boss.restoredColor }):Play()
	end
	for _, beam in parts.beams do
		beam.Color = ColorSequence.new(boss.restoredColor)
		beam.Transparency = NumberSequence.new(0.15)
	end
	for _, eye in parts.eyes do
		TweenService:Create(eye, tweenInfo, { Transparency = 1 }):Play()
	end
end

return BossService
