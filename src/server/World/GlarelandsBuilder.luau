--!strict
-- GlarelandsBuilder: the distorted mirror of Byers Station. Stage C builds the arrival
-- circle, the return Rift, and Leo's Glare Gate (mirrored, warped Lantern Lane) with
-- corrupted orange-red glows. Stage D adds the mirrors of the other landmarks.

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
		local base = origin + Vector3.new(math.cos(angle) * 260, 0, math.sin(angle) * 200)
		Parts.makePart({ name = "CorruptPole", size = Vector3.new(1, 22, 1), cframe = CFrame.new(base + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(6)), color = PALETTE.metal, material = Enum.Material.Metal, parent = folder })
		local orb = Parts.makePart({ name = "CorruptGlow", size = Vector3.new(3, 3, 3), shape = Enum.PartType.Ball, cframe = CFrame.new(base + Vector3.new(0, 23, 0)), color = CORRUPT, material = Enum.Material.Neon, canCollide = false, parent = folder })
		local light = Instance.new("PointLight")
		light.Color = CORRUPT
		light.Range = 40
		light.Brightness = 1.5
		light.Parent = orb
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
