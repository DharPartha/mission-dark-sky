--!strict
-- TownBuilder: Byers Station (fictional town): the Starlight Hub barn clubhouse with its
-- telescope deck, Lantern Lane, the main road, school, library, community center,
-- parking, sports fields, pond and dock, creek, meadow, creek trail, the covered wooden
-- bridge with the Rift, and navigation signs. Placeholder art from Roblox parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local StreetBuilder = require(script.Parent:WaitForChild("StreetBuilder"))

local TownBuilder = {}

export type Town = {
	spawn: SpawnLocation,
	telescopePrompt: ProximityPrompt,
	rift: BasePart,
	riftPrompt: ProximityPrompt,
	fireflies: ParticleEmitter,
}

local PALETTE = Parts.Town
local BARN_RED = Color3.fromRGB(150, 52, 42)

local function buildFireflies(folder: Instance, center: Vector3, size: Vector3): ParticleEmitter
	local field = Parts.makePart({
		name = "MeadowFireflies",
		size = Vector3.new(size.X, 6, size.Z),
		cframe = CFrame.new(center + Vector3.new(0, 4, 0)),
		color = Color3.new(1, 1, 1),
		transparency = 1,
		canCollide = false,
		parent = folder,
	})
	field.CastShadow = false
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fireflies"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(3, 5)
	emitter.Speed = NumberRange.new(0.3, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.35)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.fromRGB(214, 255, 120))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = field
	return emitter
end


-- A plain civic building with windows, a shielded warm entrance light, and a name board.
local function building(parent: Instance, name: string, center: Vector3, size: Vector3, color: Color3, labelKey: string)
	local model = Parts.makeModel(name, parent, false)
	Parts.makePart({ name = "Walls", size = size, cframe = CFrame.new(center + Vector3.new(0, size.Y / 2, 0)), color = color, material = Enum.Material.Brick, parent = model })
	Parts.makePart({ name = "Roof", size = Vector3.new(size.X + 2, 1, size.Z + 2), cframe = CFrame.new(center + Vector3.new(0, size.Y + 0.5, 0)), color = PALETTE.roof, parent = model })
	-- Faces the main road (west).
	local front = center.X - size.X / 2 - 0.1
	for index = -1, 1 do
		Parts.makePart({ name = "Window", size = Vector3.new(0.2, 4, 6), cframe = CFrame.new(front, size.Y * 0.6, center.Z + index * size.Z / 3.5), color = PALETTE.window, material = Enum.Material.Neon, canCollide = false, parent = model })
	end
	Parts.makePart({ name = "Door", size = Vector3.new(0.3, 7, 5), cframe = CFrame.new(front, 3.5, center.Z), color = PALETTE.wood, material = Enum.Material.Wood, parent = model })
	local lamp = Parts.makePart({ name = "EntranceLight", size = Vector3.new(1, 0.4, 1.2), cframe = CFrame.new(front - 0.6, 8, center.Z), color = Color3.fromRGB(255, 200, 140), material = Enum.Material.Neon, canCollide = false, parent = model })
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 90
	light.Range = 16
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 200, 140)
	light.Parent = lamp
	local board = Parts.makePart({ name = "NameBoard", size = Vector3.new(0.3, 3, 16), cframe = CFrame.new(front - 0.2, size.Y - 3, center.Z) * CFrame.Angles(0, math.rad(90), 0), color = PALETTE.sign, canCollide = false, parent = model })
	Parts.writeOnBoard(board, labelKey)
end

local function buildHub(parent: Instance): ProximityPrompt
	local hub = WorldConfig.Town.Hub
	local model = Parts.makeModel("StarlightHub", parent)
	local size = hub.size
	local base = hub.center
	Parts.makePart({ name = "Barn", size = size, cframe = CFrame.new(base + Vector3.new(0, size.Y / 2, 0)), color = BARN_RED, material = Enum.Material.WoodPlanks, parent = model })
	-- Gable roof along X.
	local half = Vector3.new(size.X + 2, 8, size.Z / 2 + 1)
	Parts.makeWedge("RoofSouth", half, CFrame.new(base + Vector3.new(0, size.Y + 4, -half.Z / 2)), PALETTE.roof, model)
	Parts.makeWedge("RoofNorth", half, CFrame.new(base + Vector3.new(0, size.Y + 4, half.Z / 2)) * CFrame.Angles(0, math.pi, 0), PALETTE.roof, model)
	-- Big barn door and loft window face east toward Lantern Lane.
	local east = base.X + size.X / 2 + 0.1
	Parts.makePart({ name = "BarnDoor", size = Vector3.new(0.3, 12, 12), cframe = CFrame.new(east, 6, base.Z), color = Color3.fromRGB(230, 220, 200), material = Enum.Material.Wood, parent = model })
	Parts.makePart({ name = "LoftWindow", size = Vector3.new(0.3, 4, 5), cframe = CFrame.new(east, 16, base.Z), color = PALETTE.window, material = Enum.Material.Neon, canCollide = false, parent = model })
	local nameBoard = Parts.makePart({ name = "NameBoard", size = Vector3.new(0.3, 2.6, 14), cframe = CFrame.new(east + 0.2, 13.5, base.Z) * CFrame.Angles(0, math.rad(90), 0), color = PALETTE.sign, canCollide = false, parent = model })
	Parts.writeOnBoard(nameBoard, "sign_hub")
	-- Warm porch light: shielded and aimed down, the "good example" at home base.
	local porch = Parts.makePart({ name = "PorchLight", size = Vector3.new(1, 0.4, 1.4), cframe = CFrame.new(east + 0.8, 12.6, base.Z), color = Color3.fromRGB(255, 196, 130), material = Enum.Material.Neon, canCollide = false, parent = model })
	local porchLight = Instance.new("SpotLight")
	porchLight.Face = Enum.NormalId.Bottom
	porchLight.Angle = 100
	porchLight.Range = 22
	porchLight.Brightness = 1.4
	porchLight.Color = Color3.fromRGB(255, 196, 130)
	porchLight.Parent = porch

	-- Deck and telescope.
	local scope = WorldConfig.Town.Telescope
	Parts.makePart({ name = "Deck", size = Vector3.new(18, 1.2, 14), cframe = CFrame.new(scope + Vector3.new(-2, 0.6, 0)), color = PALETTE.wood, material = Enum.Material.WoodPlanks, parent = model })
	for _, angle in { 0, 120, 240 } do
		local rad = math.rad(angle)
		local foot = scope + Vector3.new(math.sin(rad) * 1.4, 1.2, math.cos(rad) * 1.4)
		local top = scope + Vector3.new(0, 4.4, 0)
		Parts.makePart({ name = "TripodLeg", size = Vector3.new(0.2, 0.2, (top - foot).Magnitude), cframe = CFrame.lookAt((foot + top) / 2, top), color = PALETTE.metal, material = Enum.Material.Metal, canCollide = false, parent = model })
	end
	local tube = Parts.makePart({
		name = "TelescopeTube",
		size = Vector3.new(1, 1, 4.5),
		cframe = CFrame.lookAt(scope + Vector3.new(0, 4.8, 0), scope + Vector3.new(4, 8, -4)),
		color = Color3.fromRGB(230, 230, 240),
		material = Enum.Material.Metal,
		canCollide = false,
		parent = model,
	})
	local interactable = WorldConfig.Interactables.telescope
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TelescopePrompt"
	prompt.ActionText = Text.get(interactable.actionKey)
	prompt.ObjectText = Text.get(interactable.objectKey)
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("InteractableId", "telescope")
	prompt.Parent = tube
	return prompt
end

local function buildCivic(parent: Instance)
	local town = WorldConfig.Town
	local folder = Parts.makeFolder("Civic", parent)
	-- Lantern Lane joins the main road.
	Parts.strip("LaneLink", Vector3.new(120, 0, 0), Vector3.new(town.MainRoad.x, 0, 0), 24, 0.2, PALETTE.road, Enum.Material.Asphalt, folder, 0.1)
	Parts.strip("MainRoad", Vector3.new(town.MainRoad.x, 0, town.MainRoad.fromZ), Vector3.new(town.MainRoad.x, 0, town.MainRoad.toZ), town.MainRoad.width, 0.2, PALETTE.road, Enum.Material.Asphalt, folder, 0.1)
	building(folder, "School", town.School.center, town.School.size, Color3.fromRGB(150, 80, 70), "building_school")
	building(folder, "Library", town.Library.center, town.Library.size, Color3.fromRGB(110, 100, 140), "building_library")
	building(folder, "CommunityCenter", town.Community.center, town.Community.size, Color3.fromRGB(120, 130, 100), "building_community")

	local lot = town.Parking
	Parts.makePart({ name = "ParkingLot", size = Vector3.new(lot.size.X, 0.2, lot.size.Z), cframe = CFrame.new(lot.center + Vector3.new(0, 0.1, 0)), color = PALETTE.road, material = Enum.Material.Asphalt, parent = folder })
	for z = -lot.size.Z / 2 + 6, lot.size.Z / 2 - 6, 8 do
		Parts.makePart({ name = "Stall", size = Vector3.new(lot.size.X * 0.8, 0.05, 0.4), cframe = CFrame.new(lot.center + Vector3.new(0, 0.22, z)), color = PALETTE.stripe, canCollide = false, parent = folder })
	end

	local fields = town.SportsFields
	Parts.makePart({ name = "Field", size = Vector3.new(fields.size.X, 0.2, fields.size.Z), cframe = CFrame.new(fields.center + Vector3.new(0, 0.1, 0)), color = Color3.fromRGB(60, 110, 60), material = Enum.Material.Grass, parent = folder })
	for _, edge in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local alongX = edge[2] ~= 0
		local size = if alongX then Vector3.new(fields.size.X, 0.05, 0.6) else Vector3.new(0.6, 0.05, fields.size.Z)
		local offset = Vector3.new(edge[1] * fields.size.X / 2, 0.24, edge[2] * fields.size.Z / 2)
		Parts.makePart({ name = "FieldLine", size = size, cframe = CFrame.new(fields.center + offset), color = Color3.new(1, 1, 1), canCollide = false, parent = folder })
	end
	-- The field floodlights are town echoes of Orion's realm (FixtureConfig.Echoes.Orion).
end

local function buildNature(parent: Instance): ParticleEmitter
	local town = WorldConfig.Town
	local folder = Parts.makeFolder("Nature", parent)

	local pond = town.Pond
	local water = Parts.makePart({
		name = "Pond",
		size = Vector3.new(0.3, pond.radius * 2, pond.radius * 2),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(pond.center + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = PALETTE.water,
		material = Enum.Material.Glass,
		transparency = 0.15,
		canCollide = false,
		parent = folder,
	})
	water.CastShadow = false
	local dockStart = pond.center + Vector3.new(pond.radius - 4, 0, 0)
	Parts.makePart({ name = "Dock", size = Vector3.new(pond.dockLength, 0.6, 5), cframe = CFrame.new(dockStart + Vector3.new(-pond.dockLength / 2 + 6, 0.9, 0)), color = PALETTE.wood, material = Enum.Material.WoodPlanks, parent = folder })

	local creek = town.Creek
	local creekPart = Parts.strip("Creek", Vector3.new(creek.fromX, 0, creek.z), Vector3.new(creek.toX, 0, creek.z), creek.width, 0.3, PALETTE.water, Enum.Material.Glass, folder, 0.12)
	creekPart.CanCollide = false
	creekPart.Transparency = 0.15

	local meadow = town.Meadow
	Parts.makePart({ name = "Meadow", size = Vector3.new(meadow.size.X, 0.15, meadow.size.Z), cframe = CFrame.new(meadow.center + Vector3.new(0, 0.08, 0)), color = Color3.fromRGB(70, 96, 50), material = Enum.Material.Grass, parent = folder })

	local trail = town.Trail
	for index = 1, #trail - 1 do
		Parts.strip("Trail", trail[index], trail[index + 1], town.TrailWidth, 0.25, PALETTE.path, Enum.Material.Ground, folder, 0.13)
	end
	return buildFireflies(folder, meadow.center, meadow.size)
end

local function buildBridge(parent: Instance): (BasePart, ProximityPrompt)
	local bridge = WorldConfig.Town.Bridge
	local model = Parts.makeModel("CoveredBridge", parent)
	local c = bridge.center
	Parts.makePart({ name = "Floor", size = Vector3.new(bridge.width, 1, bridge.length), cframe = CFrame.new(c + Vector3.new(0, 0.5, 0)), color = PALETTE.wood, material = Enum.Material.WoodPlanks, parent = model })
	for _, side in { -1, 1 } do
		Parts.makePart({ name = "Wall", size = Vector3.new(0.8, bridge.height, bridge.length), cframe = CFrame.new(c + Vector3.new(side * bridge.width / 2, bridge.height / 2 + 1, 0)), color = BARN_RED, material = Enum.Material.WoodPlanks, parent = model })
	end
	-- Wedges are turned 90 degrees, so their local X runs along the bridge and Z across it.
	local run = bridge.width / 2 + 1
	local half = Vector3.new(bridge.length + 2, 5, run)
	Parts.makeWedge("RoofWest", half, CFrame.new(c + Vector3.new(-run / 2, bridge.height + 3.5, 0)) * CFrame.Angles(0, math.rad(90), 0), PALETTE.roof, model)
	Parts.makeWedge("RoofEast", half, CFrame.new(c + Vector3.new(run / 2, bridge.height + 3.5, 0)) * CFrame.Angles(0, math.rad(-90), 0), PALETTE.roof, model)

	-- The Rift: hidden until the story opens it.
	local rift = Parts.makePart({
		name = "Rift",
		size = Vector3.new(0.4, 9, 9),
		shape = Enum.PartType.Cylinder,
		cframe = CFrame.new(WorldConfig.Town.RiftPosition) * CFrame.Angles(0, math.rad(90), 0),
		color = Color3.fromRGB(255, 90, 50),
		material = Enum.Material.Neon,
		transparency = 1,
		canCollide = false,
		parent = model,
	})
	rift.CastShadow = false
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 90, 50)
	glow.Range = 24
	glow.Brightness = 2
	glow.Enabled = false
	glow.Parent = rift
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RiftPrompt"
	prompt.ActionText = Text.get("prompt_rift")
	prompt.ObjectText = Text.get("prompt_rift_object")
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = false
	prompt.Parent = rift
	return rift, prompt
end

function TownBuilder.build(parent: Instance): Town
	local town = WorldConfig.Town
	local folder = Parts.makeFolder("ByersStation", parent)
	Parts.makePart({ name = "Ground", size = Vector3.new(town.GroundSize, 2, town.GroundSize), cframe = CFrame.new(0, -1, 0), color = PALETTE.grass, material = Enum.Material.Grass, parent = folder })
	StreetBuilder.build(folder, Vector3.zero, false, PALETTE, false)
	local telescopePrompt = buildHub(folder)
	buildCivic(folder)
	local fireflies = buildNature(folder)
	local rift, riftPrompt = buildBridge(folder)
	for _, sign in WorldConfig.Signposts do
		Parts.makeSign(sign.position, sign.facingDegrees, sign.textKey, PALETTE, folder)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(town.Spawn)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = PALETTE.wood
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Parent = folder

	return { spawn = spawn, telescopePrompt = telescopePrompt, rift = rift, riftPrompt = riftPrompt, fireflies = fireflies }
end

return TownBuilder
