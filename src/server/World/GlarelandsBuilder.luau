--!strict
-- GlarelandsBuilder: the distorted mirror of Byers Station: arrival circle, return Rift,
-- Leo's Glare Gate (mirrored, warped Lantern Lane), Orion's field, Scorpius's meadow and
-- creek with the shed, Cetus's pond with dock and boathouse, paths, signs, and corrupted glows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local StreetBuilder = require(script.Parent:WaitForChild("StreetBuilder"))

local GlarelandsBuilder = {}

export type Glarelands = { rift: BasePart, riftPrompt: ProximityPrompt }

local PALETTE = Parts.Glare
local CORRUPT = Color3.fromRGB(255, 90, 50)

function GlarelandsBuilder.build(parent: Instance): Glarelands
	local config = WorldConfig.Glarelands
	local origin = WorldConfig.GlarelandsOffset
	local folder = Parts.makeFolder("Glarelands", parent)

	Parts.makePart({
		name = "Ground",
		size = Vector3.new(config.GroundSize, 2, config.GroundSize),
		cframe = CFrame.new(origin + Vector3.new(0, -1, 0)),
		color = PALETTE.grass,
		material = Enum.Material.Slate,
		parent = folder,
	})
	StreetBuilder.build(folder, origin, true, PALETTE, true)

	-- Arrival circle so players know they landed somewhere safe.
	local arrival = config.Arrival
	Parts.makePart({
		name = "ArrivalCircle",
		size = Vector3.new(0.4, 22, 22),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(Vector3.new(arrival.X, 0.2, arrival.Z)) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(70, 60, 90),
		material = Enum.Material.Slate,
		parent = folder,
	})

	-- Corrupted glows: harsh unshielded beacons around the edges (scenery, not puzzles).
	for index = 0, 7 do
		local angle = math.rad(index * 45)
		-- Far enough out to stay clear of every realm arena.
		local base = origin + Vector3.new(math.cos(angle) * 340, 0, math.sin(angle) * 360)
		Parts.makePart({ name = "CorruptPole", size = Vector3.new(1, 22, 1), cframe = CFrame.new(base + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(6)), color = PALETTE.metal, material = Enum.Material.Metal, parent = folder })
		local orb = Parts.makePart({ name = "CorruptGlow", size = Vector3.new(3, 3, 3), shape = Enum.PartType.Ball, cframe = CFrame.new(base + Vector3.new(0, 23, 0)), color = CORRUPT, material = Enum.Material.Neon, canCollide = false, parent = folder })
		local light = Instance.new("PointLight")
		light.Color = CORRUPT
		light.Range = 40
		light.Brightness = 1.5
		light.Parent = orb
	end

	-- Realm landmarks: mirrors of the town's fields, meadow and creek, and pond.
	local fields = config.SportsFields
	Parts.makePart({ name = "OrionField", size = Vector3.new(fields.size.X, 0.2, fields.size.Z), cframe = CFrame.new(fields.center + Vector3.new(0, 0.1, 0)), color = Color3.fromRGB(30, 46, 36), material = Enum.Material.Grass, parent = folder })
	for _, edge in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local alongX = edge[2] ~= 0
		local size = if alongX then Vector3.new(fields.size.X, 0.05, 0.6) else Vector3.new(0.6, 0.05, fields.size.Z)
		Parts.makePart({ name = "FieldLine", size = size, cframe = CFrame.new(fields.center + Vector3.new(edge[1] * fields.size.X / 2, 0.24, edge[2] * fields.size.Z / 2)), color = PALETTE.stripe, canCollide = false, parent = folder })
	end
	-- Scoreboard behind the uplight (the uplight lights the sky more than the board).
	Parts.makePart({ name = "Scoreboard", size = Vector3.new(24, 10, 1), cframe = CFrame.new(fields.center + Vector3.new(0, 9, 60)), color = PALETTE.sign, parent = folder })
	Parts.makePart({ name = "ScoreboardPost", size = Vector3.new(1, 4, 1), cframe = CFrame.new(fields.center + Vector3.new(0, 2, 60)), color = PALETTE.metal, parent = folder })

	local meadow = config.Meadow
	Parts.makePart({ name = "ScorpiusMeadow", size = Vector3.new(meadow.size.X, 0.15, meadow.size.Z), cframe = CFrame.new(meadow.center + Vector3.new(0, 0.08, 0)), color = Color3.fromRGB(34, 44, 40), material = Enum.Material.Grass, parent = folder })
	local creek = config.Creek
	local creekPart = Parts.strip("Creek", Vector3.new(creek.fromX, 0, creek.z), Vector3.new(creek.toX, 0, creek.z), creek.width, 0.3, PALETTE.water, Enum.Material.Glass, folder, 0.12)
	creekPart.CanCollide = false
	local shed = config.Shed
	Parts.makePart({ name = "Shed", size = shed.size, cframe = CFrame.new(shed.center + Vector3.new(0, shed.size.Y / 2, 0)), color = PALETTE.houseWalls[2], material = Enum.Material.WoodPlanks, parent = folder })

	local pond = config.Pond
	local water = Parts.makePart({
		name = "CetusPond",
		size = Vector3.new(0.3, pond.radius * 2, pond.radius * 2),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(pond.center + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = PALETTE.water,
		material = Enum.Material.Glass,
		transparency = 0.1,
		canCollide = false,
		parent = folder,
	})
	water.CastShadow = false
	Parts.strip("Dock", config.Dock.from, config.Dock.to, 5, 0.6, PALETTE.wood, Enum.Material.WoodPlanks, folder, 0.9)
	local boathouse = config.Boathouse
	Parts.makePart({ name = "Boathouse", size = boathouse.size, cframe = CFrame.new(boathouse.center + Vector3.new(0, boathouse.size.Y / 2, 0)), color = PALETTE.houseWalls[3], material = Enum.Material.WoodPlanks, parent = folder })

	for _, path in config.Paths do
		Parts.strip("GlarePath", path[1], path[2], 9, 0.25, PALETTE.path, Enum.Material.Ground, folder, 0.13)
	end
	for _, sign in config.Signposts do
		Parts.makeSign(sign.position, sign.facingDegrees, sign.textKey, PALETTE, folder)
	end

	-- Return Rift (always open from this side so nobody gets stranded).
	local rift = Parts.makePart({
		name = "ReturnRift",
		size = Vector3.new(0.4, 9, 9),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(config.RiftPosition) * CFrame.Angles(0, 0, 0),
		color = CORRUPT,
		material = Enum.Material.Neon,
		transparency = 0.15,
		canCollide = false,
		parent = folder,
	})
	rift.CastShadow = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ReturnPrompt"
	prompt.ActionText = Text.get("prompt_rift_back")
	prompt.ObjectText = Text.get("prompt_rift_object")
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = rift

	return { rift = rift, riftPrompt = prompt }
end

return GlarelandsBuilder
