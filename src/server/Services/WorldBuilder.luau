--!strict
-- WorldBuilder: builds the Milestone 1 test area, "Lantern Lane" in Byers Station, from
-- simple Roblox parts (placeholder art), and applies fixture state to the visible lights.
--
-- Inputs: FixtureConfig (fixture positions), BossConfig (Leo star layout), Tuning (visuals).
-- Outputs: a Workspace folder with tagged zone/fixture models, NPC friends, Leo, the Moon,
-- and handles other services use (prompts, Leo parts, Moon parts, firefly emitter).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local Types = require(SharedFolder:WaitForChild("Types"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local Text = require(SharedFolder:WaitForChild("Text"))

local WorldBuilder = {}

export type FixtureParts = {
	def: Types.FixtureDefinition,
	model: Model,
	head: BasePart,
	spot: SpotLight,
	glow: PointLight,
	halo: BasePart,
	shield: { BasePart },
	prompt: ProximityPrompt,
	anchor: BasePart,
}

export type LeoParts = {
	stars: { BasePart },
	beams: { Beam },
	eyes: { BasePart },
}

export type MoonParts = {
	body: BasePart,
	glow: BasePart,
	glintEye: BasePart,
}

export type World = {
	folder: Folder,
	fixtures: { [string]: FixtureParts },
	npcPrompts: { [string]: ProximityPrompt },
	leo: LeoParts,
	moon: MoonParts,
	fireflies: ParticleEmitter,
	spawn: SpawnLocation,
}

-- Tags let other scripts find zones and fixtures without hard-coded paths.
WorldBuilder.Tags = { Zone = "DarkSkyZone", Fixture = "DarkSkyFixture", Npc = "DarkSkyNpc" }

local COLORS = {
	grass = Color3.fromRGB(46, 70, 44),
	road = Color3.fromRGB(42, 43, 48),
	sidewalk = Color3.fromRGB(128, 126, 120),
	stripe = Color3.fromRGB(226, 222, 206),
	houseWalls = { Color3.fromRGB(150, 116, 92), Color3.fromRGB(112, 128, 150), Color3.fromRGB(160, 150, 120) },
	roof = Color3.fromRGB(70, 52, 48),
	window = Color3.fromRGB(255, 196, 120),
	metal = Color3.fromRGB(58, 60, 66),
	crossingPole = Color3.fromRGB(214, 176, 46),
	sign = Color3.fromRGB(34, 74, 140),
}

local FRIEND_LAYOUT = {
	{ name = "Aadi", offset = Vector3.new(-76, 0, 27), shirt = Color3.fromRGB(214, 120, 52) },
	{ name = "Aditya", offset = Vector3.new(-71, 0, 28), shirt = Color3.fromRGB(64, 140, 196) },
	{ name = "Adrika", offset = Vector3.new(-66, 0, 27), shirt = Color3.fromRGB(150, 92, 190) },
}

type PartProps = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
	canCollide: boolean?,
	parent: Instance,
}

local function makePart(props: PartProps): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Shape = props.shape or Enum.PartType.Block
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = if props.canCollide == nil then true else props.canCollide
	part.CastShadow = props.canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function makeModel(name: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	-- Keep small, important models loaded for every player when streaming is on.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = parent
	return model
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

local function buildGround(folder: Folder): SpawnLocation
	local street = Instance.new("Folder")
	street.Name = "Street"
	street.Parent = folder

	makePart({
		name = "Ground",
		size = Vector3.new(700, 2, 700),
		cframe = CFrame.new(0, -1, 0),
		color = COLORS.grass,
		material = Enum.Material.Grass,
		parent = street,
	})
	makePart({
		name = "Road",
		size = Vector3.new(240, 0.2, 24),
		cframe = CFrame.new(0, 0.1, 0),
		color = COLORS.road,
		material = Enum.Material.Asphalt,
		parent = street,
	})
	for x = -110, 110, 16 do
		makePart({
			name = "LaneMark",
			size = Vector3.new(7, 0.05, 0.5),
			cframe = CFrame.new(x, 0.22, 0),
			color = COLORS.stripe,
			canCollide = false,
			parent = street,
		})
	end
	for _, z in { 16, -16 } do
		makePart({
			name = "Sidewalk",
			size = Vector3.new(240, 0.5, 8),
			cframe = CFrame.new(0, 0.25, z),
			color = COLORS.sidewalk,
			material = Enum.Material.Concrete,
			parent = street,
		})
	end
	-- Crosswalk stripes next to the safety-critical crossing light.
	for z = -10, 10, 3 do
		makePart({
			name = "CrosswalkStripe",
			size = Vector3.new(6, 0.05, 1.6),
			cframe = CFrame.new(34, 0.22, z),
			color = COLORS.stripe,
			canCollide = false,
			parent = street,
		})
	end
	-- Driveway under the garage floodlight.
	makePart({
		name = "Driveway",
		size = Vector3.new(12, 0.3, 14),
		cframe = CFrame.new(6, 0.15, 27),
		color = COLORS.sidewalk,
		material = Enum.Material.Concrete,
		parent = street,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LaneSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(-86, 0.5, 16)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = COLORS.sidewalk
	spawn.Material = Enum.Material.Concrete
	spawn.Parent = street
	return spawn
end

local function buildHouses(folder: Folder)
	local houses = Instance.new("Folder")
	houses.Name = "Houses"
	houses.Parent = folder

	for index, x in { -50, 6, 60 } do
		local model = makeModel("House" .. index, houses)
		local wallColor = COLORS.houseWalls[index]
		makePart({
			name = "Walls",
			size = Vector3.new(26, 14, 20),
			cframe = CFrame.new(x, 7, 44),
			color = wallColor,
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
		local roof = Instance.new("WedgePart")
		roof.Name = "RoofFront"
		roof.Size = Vector3.new(27, 6, 11)
		-- A wedge's slope faces -Z by default, which is toward the street.
		roof.CFrame = CFrame.new(x, 17, 38.5)
		roof.Color = COLORS.roof
		roof.Anchored = true
		roof.Parent = model
		local roofBack = roof:Clone()
		roofBack.Name = "RoofBack"
		roofBack.CFrame = CFrame.new(x, 17, 49.5) * CFrame.Angles(0, math.pi, 0)
		roofBack.Parent = model
		-- Warm windows read as homes whose sleep the glare disturbs.
		for _, wx in { -7, 7 } do
			makePart({
				name = "Window",
				size = Vector3.new(4, 4, 0.2),
				cframe = CFrame.new(x + wx, 8, 33.95),
				color = COLORS.window,
				material = Enum.Material.Neon,
				canCollide = false,
				parent = model,
			})
		end
		makePart({
			name = "Door",
			size = Vector3.new(4, 7, 0.3),
			cframe = CFrame.new(x + (if index == 2 then 9 else 0), 3.5, 33.9),
			color = Color3.fromRGB(70, 46, 36),
			material = Enum.Material.Wood,
			parent = model,
		})
	end
end

local function buildCrossingSign(folder: Folder)
	local model = makeModel("CrossingSign", folder)
	makePart({
		name = "Post",
		size = Vector3.new(0.4, 7, 0.4),
		cframe = CFrame.new(41, 3.5, -18),
		color = COLORS.metal,
		material = Enum.Material.Metal,
		parent = model,
	})
	local board = makePart({
		name = "Board",
		size = Vector3.new(6, 3, 0.3),
		cframe = CFrame.new(41, 7, -18),
		color = COLORS.sign,
		parent = model,
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = Text.get("sign_crossing")
		label.Parent = gui
	end
end

-- Head orientation: face the fixture's direction, then tilt the bottom of the head
-- toward that direction by the aim angle (0 = pointing straight down).
local function headCFrame(def: Types.FixtureDefinition, aim: string): CFrame
	local yaw = math.rad(def.facingDegrees) + math.pi
	local tilt = math.rad((Tuning.Fixture.AimTiltDegrees :: any)[aim] or 0)
	return CFrame.new(def.position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tilt, 0, 0)
end

local function buildFixture(def: Types.FixtureDefinition, zoneModel: Model): FixtureParts
	local model = makeModel(def.id, zoneModel)
	model:SetAttribute("FixtureId", def.id)
	CollectionService:AddTag(model, WorldBuilder.Tags.Fixture)

	local facing = Vector3.new(math.sin(math.rad(def.facingDegrees)), 0, math.cos(math.rad(def.facingDegrees)))
	local headPosition = def.position

	if def.kind == "Floodlight" then
		-- Bracket from the house wall to the lamp head.
		makePart({
			name = "Bracket",
			size = Vector3.new(0.4, 0.4, 3),
			cframe = CFrame.lookAt(headPosition - facing * 1.5, headPosition),
			color = COLORS.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
	else
		local poleBase = Vector3.new(headPosition.X, 0, headPosition.Z) - facing * 4
		local poleHeight = headPosition.Y + 1
		makePart({
			name = "Pole",
			size = Vector3.new(0.7, poleHeight, 0.7),
			cframe = CFrame.new(poleBase + Vector3.new(0, poleHeight / 2, 0)),
			color = if def.kind == "Crossing" then COLORS.crossingPole else COLORS.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
		local armStart = poleBase + Vector3.new(0, headPosition.Y + 0.8, 0)
		local armEnd = headPosition + Vector3.new(0, 0.8, 0)
		makePart({
			name = "Arm",
			size = Vector3.new(0.4, 0.4, (armEnd - armStart).Magnitude),
			cframe = CFrame.lookAt((armStart + armEnd) / 2, armEnd),
			color = COLORS.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
	end

	local head = makePart({
		name = "Head",
		size = Vector3.new(3, 0.8, 2),
		cframe = headCFrame(def, def.initial.aim),
		color = Color3.new(1, 1, 1),
		material = Enum.Material.Neon,
		canCollide = false,
		parent = model,
	})

	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 110
	spot.Range = Tuning.Fixture.SpotRange
	spot.Shadows = true
	spot.Parent = head

	-- The glow light and halo show escaping glare; both fade as glare is fixed.
	local glow = Instance.new("PointLight")
	glow.Shadows = false
	glow.Parent = head

	local halo = makePart({
		name = "GlareHalo",
		size = Vector3.new(7, 7, 7),
		shape = Enum.PartType.Ball,
		cframe = CFrame.new(headPosition),
		color = Color3.new(1, 1, 1),
		material = Enum.Material.Neon,
		transparency = 1,
		canCollide = false,
		parent = model,
	})
	halo.CastShadow = false

	-- Full-cutoff shield: a hood over the head, hidden until SHIELD is applied.
	local shield: { BasePart } = {}
	local hoodPieces = {
		{ size = Vector3.new(3.6, 0.25, 2.6), offset = Vector3.new(0, 0.55, 0) },
		{ size = Vector3.new(3.6, 1.1, 0.15), offset = Vector3.new(0, 0.05, 1.25) },
		{ size = Vector3.new(3.6, 1.1, 0.15), offset = Vector3.new(0, 0.05, -1.25) },
		{ size = Vector3.new(0.15, 1.1, 2.6), offset = Vector3.new(1.75, 0.05, 0) },
		{ size = Vector3.new(0.15, 1.1, 2.6), offset = Vector3.new(-1.75, 0.05, 0) },
	}
	for index, piece in hoodPieces do
		local part = makePart({
			name = "Shield" .. index,
			size = piece.size,
			cframe = head.CFrame * CFrame.new(piece.offset),
			color = Color3.fromRGB(30, 32, 36),
			material = Enum.Material.Metal,
			transparency = 1,
			canCollide = false,
			parent = model,
		})
		part:SetAttribute("Offset", piece.offset)
		table.insert(shield, part)
	end

	-- Prompt anchor at player height so the prompt is easy to reach and tap.
	local anchorPosition = if def.kind == "Floodlight"
		then Vector3.new(headPosition.X, 3.5, headPosition.Z) + facing * 3
		else Vector3.new(headPosition.X, 3.5, headPosition.Z) - facing * 3
	local anchor = makePart({
		name = "PromptAnchor",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new(anchorPosition),
		color = Color3.new(1, 1, 1),
		transparency = 1,
		canCollide = false,
		parent = model,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InspectPrompt"
	prompt.ActionText = Text.get("prompt_inspect")
	prompt.ObjectText = Text.get(def.nameKey)
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("FixtureId", def.id)
	prompt.Parent = anchor

	model.PrimaryPart = head
	return {
		def = def,
		model = model,
		head = head,
		spot = spot,
		glow = glow,
		halo = halo,
		shield = shield,
		prompt = prompt,
		anchor = anchor,
	}
end

-- Shows a fixture's state in the world. Server-side so every player sees the same light.
function WorldBuilder.applyFixtureVisual(parts: FixtureParts, state: Types.FixtureState)
	local fixtureTuning = Tuning.Fixture
	local readings = DarknessMath.readFixture(parts.def, state)
	local color = (fixtureTuning.ColorTempRGB :: any)[state.colorTempK] or Color3.new(1, 1, 1)

	parts.head.CFrame = headCFrame(parts.def, state.aim)
	for _, piece in parts.shield do
		local offset = piece:GetAttribute("Offset")
		if typeof(offset) == "Vector3" then
			piece.CFrame = parts.head.CFrame * CFrame.new(offset)
		end
		piece.Transparency = if state.shielded then 0 else 1
	end

	parts.head.Color = color
	parts.head.Transparency = if state.on then 0.05 + (1 - readings.brightness) * 0.45 else 0.85
	parts.spot.Enabled = state.on
	parts.spot.Color = color
	parts.spot.Brightness = readings.brightness * fixtureTuning.SpotBrightnessAtFull
	-- Shielded heads throw a tighter, downward cone.
	parts.spot.Angle = if state.shielded then 80 else 120

	parts.glow.Enabled = state.on and readings.glare > 0.05
	parts.glow.Color = color
	parts.glow.Brightness = readings.glare * fixtureTuning.GlowBrightnessAtFull
	parts.glow.Range = 6 + readings.glare * fixtureTuning.GlowRangeAtFull

	parts.halo.Color = color
	parts.halo.Transparency = 1 - math.clamp(readings.glare * 0.55, 0, 0.55)
end

local function buildNpc(layout: { name: string, offset: Vector3, shirt: Color3 }, parent: Instance): (Model, ProximityPrompt)
	local lookAt = Vector3.new(layout.offset.X, 0, 0)
	local model: Model? = nil

	-- Yields while avatar assets load; falls back to a block figure if it fails.
	local ok, result = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.TorsoColor = layout.shirt
		description.LeftArmColor = layout.shirt
		description.RightArmColor = layout.shirt
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		model = result
	end

	if model == nil then
		local fallback = Instance.new("Model")
		local body = makePart({
			name = "HumanoidRootPart",
			size = Vector3.new(2, 3, 1),
			cframe = CFrame.new(layout.offset + Vector3.new(0, 2.5, 0)),
			color = layout.shirt,
			parent = fallback,
		})
		makePart({
			name = "Head",
			size = Vector3.new(1.4, 1.4, 1.4),
			cframe = CFrame.new(layout.offset + Vector3.new(0, 4.8, 0)),
			color = Color3.fromRGB(196, 150, 110),
			parent = fallback,
		})
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = fallback
		fallback.PrimaryPart = body
		model = fallback
	end

	local npc = model :: Model
	npc.Name = layout.name
	npc.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	npc:SetAttribute("Speaker", layout.name)
	CollectionService:AddTag(npc, WorldBuilder.Tags.Npc)
	for _, descendant in npc:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	local pivot = layout.offset + Vector3.new(0, 3, 0)
	npc:PivotTo(CFrame.lookAt(pivot, Vector3.new(lookAt.X, pivot.Y, lookAt.Z)))

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = (DialogueConfig.Speakers :: any)[layout.name].displayName
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		humanoid.NameDisplayDistance = 60
	end
	npc.Parent = parent

	local promptParent = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = Text.get("prompt_talk")
	prompt.ObjectText = (DialogueConfig.Speakers :: any)[layout.name].displayName
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt:SetAttribute("Speaker", layout.name)
	prompt.Parent = promptParent
	return npc, prompt
end

local function buildLeo(folder: Folder): LeoParts
	local boss = BossConfig.Leo
	local model = makeModel("Leo", folder)
	local stars: { BasePart } = {}
	local beams: { Beam } = {}
	local attachments: { [string]: Attachment } = {}

	local function starPosition(u: number, v: number): Vector3
		-- Lion faces the players' right (+Z) as they look east down the lane.
		return boss.panelCenter + Vector3.new(0, (v - 6) * boss.gridScale, -(u - 10) * boss.gridScale)
	end

	for starName, point in boss.starPoints do
		local star = makePart({
			name = starName,
			size = Vector3.new(5, 5, 5),
			shape = Enum.PartType.Ball,
			cframe = CFrame.new(starPosition(point.u, point.v)),
			color = boss.corruptedColor,
			material = Enum.Material.Neon,
			canCollide = false,
			parent = model,
		})
		star.CastShadow = false
		local attachment = Instance.new("Attachment")
		attachment.Parent = star
		attachments[starName] = attachment
		table.insert(stars, star)
	end

	for _, pair in boss.lines do
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachments[pair[1]]
		beam.Attachment1 = attachments[pair[2]]
		beam.Width0 = 1.2
		beam.Width1 = 1.2
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Color = ColorSequence.new(boss.corruptedColor)
		beam.Transparency = NumberSequence.new(0.3)
		beam.Parent = model
		table.insert(beams, beam)
	end

	-- Glaring eyes near the sickle (head). They vanish when Leo is calmed.
	local eyes: { BasePart } = {}
	for _, offset in { Vector3.new(-4, 2, 3), Vector3.new(-4, 2, -3) } do
		local eye = makePart({
			name = "Eye",
			size = Vector3.new(3, 3, 3),
			shape = Enum.PartType.Ball,
			cframe = CFrame.new(starPosition(1, 9) + offset),
			color = Color3.fromRGB(255, 60, 30),
			material = Enum.Material.Neon,
			canCollide = false,
			parent = model,
		})
		table.insert(eyes, eye)
	end

	return { stars = stars, beams = beams, eyes = eyes }
end

local function buildMoon(folder: Folder): MoonParts
	local model = makeModel("Moon", folder)
	local center = Vector3.new(-140, 175, -230)
	local face = CFrame.lookAt(center, Vector3.new(0, 20, 0))

	local body = makePart({
		name = "Body",
		size = Vector3.new(44, 44, 44),
		shape = Enum.PartType.Ball,
		cframe = face,
		color = Color3.fromRGB(236, 232, 206),
		material = Enum.Material.Neon,
		transparency = 0.25,
		canCollide = false,
		parent = model,
	})
	local glow = makePart({
		name = "Glow",
		size = Vector3.new(60, 60, 60),
		shape = Enum.PartType.Ball,
		cframe = face,
		color = Color3.fromRGB(240, 236, 214),
		material = Enum.Material.Neon,
		transparency = 0.9,
		canCollide = false,
		parent = model,
	})
	local eyes = {}
	for _, side in { -1, 1 } do
		local eye = makePart({
			name = "Eye",
			size = Vector3.new(4, 6, 4),
			shape = Enum.PartType.Ball,
			cframe = face * CFrame.new(side * 7, 5, -21),
			color = Color3.fromRGB(40, 40, 52),
			canCollide = false,
			parent = model,
		})
		table.insert(eyes, eye)
	end
	-- Foreshadowing: a brief red glint in one eye when the Moon gives a tip.
	local glint = makePart({
		name = "Glint",
		size = Vector3.new(2, 2, 2),
		shape = Enum.PartType.Ball,
		cframe = face * CFrame.new(7, 6, -23),
		color = Color3.fromRGB(255, 40, 40),
		material = Enum.Material.Neon,
		transparency = 1,
		canCollide = false,
		parent = model,
	})
	return { body = body, glow = glow, glintEye = glint }
end

local function buildFireflies(folder: Folder): ParticleEmitter
	local field = makePart({
		name = "MeadowFireflies",
		size = Vector3.new(160, 6, 50),
		cframe = CFrame.new(0, 4, -55),
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

function WorldBuilder.build(): World
	local existing = Workspace:FindFirstChild("DarkSkyWorld")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "DarkSkyWorld"
	folder.Parent = Workspace

	setupLighting()
	local spawn = buildGround(folder)
	buildHouses(folder)
	buildCrossingSign(folder)

	local fixtures: { [string]: FixtureParts } = {}
	for zoneId, zone in FixtureConfig.Zones do
		local zoneModel = makeModel("Zone_" .. zoneId, folder)
		zoneModel:SetAttribute("ZoneId", zoneId)
		CollectionService:AddTag(zoneModel, WorldBuilder.Tags.Zone)
		for _, def in zone.fixtures do
			local parts = buildFixture(def :: any, zoneModel)
			WorldBuilder.applyFixtureVisual(parts, def.initial :: any)
			fixtures[def.id] = parts
		end
	end

	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "Friends"
	npcFolder.Parent = folder
	local npcPrompts: { [string]: ProximityPrompt } = {}
	for _, layout in FRIEND_LAYOUT do
		local _, prompt = buildNpc(layout, npcFolder)
		npcPrompts[layout.name] = prompt
	end

	return {
		folder = folder,
		fixtures = fixtures,
		npcPrompts = npcPrompts,
		leo = buildLeo(folder),
		moon = buildMoon(folder),
		fireflies = buildFireflies(folder),
		spawn = spawn,
	}
end

return WorldBuilder
