--!strict
-- FixtureBuilder: the light fixture models (streetlight, floodlight, crossing light) and
-- how a fixture's state shows in the world: head tilt for AIM, hood for SHIELD, color for
-- WARM, light strength for DIM, and a glare halo that fades as glare is fixed.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local Tuning = require(Root:WaitForChild("Config"):WaitForChild("Tuning"))
local SharedFolder = Root:WaitForChild("Shared")
local Types = require(SharedFolder:WaitForChild("Types"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local Text = require(SharedFolder:WaitForChild("Text"))

local Parts = require(script.Parent:WaitForChild("Parts"))

local FixtureBuilder = {}

FixtureBuilder.Tag = "DarkSkyFixture"

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

-- Head orientation: face the fixture's direction, then tilt the bottom of the head
-- toward that direction by the aim angle (0 = pointing straight down).
local function headCFrame(def: Types.FixtureDefinition, aim: string): CFrame
	local yaw = math.rad(def.facingDegrees) + math.pi
	local tilt = math.rad((Tuning.Fixture.AimTiltDegrees :: any)[aim] or 0)
	return CFrame.new(def.position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(tilt, 0, 0)
end

-- decorative = true builds a town echo: same look, no Inspect prompt.
function FixtureBuilder.build(def: Types.FixtureDefinition, zoneModel: Model, palette: Parts.Palette, decorative: boolean?): FixtureParts
	local model = Parts.makeModel(def.id, zoneModel)
	model:SetAttribute("FixtureId", def.id)
	CollectionService:AddTag(model, FixtureBuilder.Tag)

	local facing = Vector3.new(math.sin(math.rad(def.facingDegrees)), 0, math.cos(math.rad(def.facingDegrees)))
	local headPosition = def.position

	if def.kind == "Floodlight" then
		-- Bracket from the house wall to the lamp head.
		Parts.makePart({
			name = "Bracket",
			size = Vector3.new(0.4, 0.4, 3),
			cframe = CFrame.lookAt(headPosition - facing * 1.5, headPosition),
			color = palette.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
	elseif def.kind == "Ground" then
		-- Ground-mounted accent or uplight: a short housing under the head.
		Parts.makePart({
			name = "Housing",
			size = Vector3.new(2, headPosition.Y, 2),
			cframe = CFrame.new(Vector3.new(headPosition.X, headPosition.Y / 2, headPosition.Z)),
			color = palette.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
	else
		local poleBase = Vector3.new(headPosition.X, 0, headPosition.Z) - facing * 4
		local poleHeight = headPosition.Y + 1
		Parts.makePart({
			name = "Pole",
			size = Vector3.new(0.7, poleHeight, 0.7),
			cframe = CFrame.new(poleBase + Vector3.new(0, poleHeight / 2, 0)),
			color = if def.kind == "Crossing" then palette.crossingPole else palette.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
		local armStart = poleBase + Vector3.new(0, headPosition.Y + 0.8, 0)
		local armEnd = headPosition + Vector3.new(0, 0.8, 0)
		Parts.makePart({
			name = "Arm",
			size = Vector3.new(0.4, 0.4, (armEnd - armStart).Magnitude),
			cframe = CFrame.lookAt((armStart + armEnd) / 2, armEnd),
			color = palette.metal,
			material = Enum.Material.Metal,
			parent = model,
		})
	end

	local head = Parts.makePart({
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

	local halo = Parts.makePart({
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
		local part = Parts.makePart({
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
	local anchor = Parts.makePart({
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
	prompt.Enabled = not decorative
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
function FixtureBuilder.applyVisual(parts: FixtureParts, state: Types.FixtureState)
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

return FixtureBuilder
