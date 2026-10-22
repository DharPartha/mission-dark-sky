--!strict
-- LuxLensController: the Lux Lens overlay. When on, every fixture shows a reading tag
-- (glare, sky glow, color) and its glare zone is drawn on the ground as a red circle.
-- Outside the circles is safe shadow from Leo's roar. Readings are game estimates.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local LuxLensController = {}

type Overlay = { tag: BillboardGui, tagText: TextLabel, disc: Part, discLabel: TextLabel }

local enabled = false
local fixturesState: Folder
local overlayFolder: Folder
local overlays: { [string]: Overlay } = {}
local definitions: { [string]: any } = {}
for _, zone in FixtureConfig.Zones do
	for _, def in zone.fixtures do
		definitions[def.id] = def
	end
end

local function stateFrom(folder: Instance): any
	return {
		on = folder:GetAttribute("On") == true,
		brightness = folder:GetAttribute("Brightness") or 0,
		shielded = folder:GetAttribute("Shielded") == true,
		aim = folder:GetAttribute("Aim") or "Down",
		colorTempK = folder:GetAttribute("ColorTempK") or 3000,
		schedule = folder:GetAttribute("Schedule") or "AllNight",
	}
end

local function buildOverlay(fixtureId: string): Overlay
	local def = definitions[fixtureId]
	local anchor = Instance.new("Part")
	anchor.Name = fixtureId .. "_LensAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(def.position + Vector3.new(0, 4, 0))
	anchor.Parent = overlayFolder

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(190, 84)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 160
	tag.Adornee = anchor
	tag.Parent = anchor
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = UiKit.Colors.panel
	back.BackgroundTransparency = 0.15
	UiKit.corner(back, 8)
	back.Parent = tag
	local tagText = Instance.new("TextLabel")
	tagText.Size = UDim2.fromScale(1, 1)
	tagText.BackgroundTransparency = 1
	tagText.TextColor3 = UiKit.Colors.text
	tagText.Font = Enum.Font.GothamBold
	tagText.TextSize = 14
	tagText.TextWrapped = true
	tagText.Parent = back

	-- Flat cylinder lying on the ground (a cylinder's axis is X, so roll it 90 degrees).
	local disc = Instance.new("Part")
	disc.Name = fixtureId .. "_GlareZone"
	disc.Shape = Enum.PartType.Cylinder
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CastShadow = false
	disc.Material = Enum.Material.Neon
	disc.Color = Color3.fromRGB(255, 70, 50)
	disc.Transparency = 0.75
	disc.Parent = overlayFolder
	local discGui = Instance.new("BillboardGui")
	discGui.Size = UDim2.fromOffset(120, 30)
	discGui.StudsOffset = Vector3.new(0, 2, 0)
	discGui.AlwaysOnTop = true
	discGui.MaxDistance = 160
	discGui.Parent = disc
	local discLabel = Instance.new("TextLabel")
	discLabel.Size = UDim2.fromScale(1, 1)
	discLabel.BackgroundColor3 = Color3.fromRGB(120, 20, 10)
	discLabel.BackgroundTransparency = 0.2
	discLabel.TextColor3 = Color3.new(1, 1, 1)
	discLabel.Font = Enum.Font.GothamBold
	discLabel.TextSize = 14
	UiKit.corner(discLabel, 6)
	discLabel.Parent = discGui

	return { tag = tag, tagText = tagText, disc = disc, discLabel = discLabel }
end

local function refresh(fixtureId: string)
	local overlay = overlays[fixtureId]
	local folder = fixturesState:FindFirstChild(fixtureId)
	local def = definitions[fixtureId]
	if overlay == nil or folder == nil or def == nil then
		return
	end
	local state = stateFrom(folder)
	local readings = DarknessMath.readFixture(def, state)
	overlay.tag.Enabled = enabled
	overlay.tagText.Text = string.format(
		"%s\n%s: %s  %s: %s\n%s",
		Text.get(def.nameKey),
		Text.get("reading_glare"),
		Text.get("reading_value_10", DarknessMath.toTen(readings.glare)),
		Text.get("reading_uplight"),
		Text.get("reading_value_10", DarknessMath.toTen(readings.uplight)),
		Text.get("reading_kelvin", state.colorTempK)
	)

	local zone = DarknessMath.glareZone(def, state)
	if enabled and zone then
		overlay.disc.Size = Vector3.new(0.3, zone.radius * 2, zone.radius * 2)
		overlay.disc.CFrame = CFrame.new(zone.x, 0.35, zone.z) * CFrame.Angles(0, 0, math.rad(90))
		overlay.disc.Transparency = 0.75
		overlay.discLabel.Text = "⚠ " .. Text.get("reading_glare") .. " " .. Text.get("reading_value_10", DarknessMath.toTen(zone.glare))
		overlay.discLabel.Visible = true
	else
		overlay.disc.Transparency = 1
		overlay.discLabel.Visible = false
	end
end

local function refreshAll()
	for fixtureId in overlays do
		refresh(fixtureId)
	end
end

function LuxLensController.toggle(): boolean
	enabled = not enabled
	refreshAll()
	return enabled
end

function LuxLensController.init(stateFolder: Folder)
	fixturesState = stateFolder:WaitForChild("Fixtures") :: Folder
	overlayFolder = Instance.new("Folder")
	overlayFolder.Name = "DarkSkyLensOverlay"
	-- Under the camera: local-only and never streamed out.
	overlayFolder.Parent = Workspace.CurrentCamera

	for fixtureId in definitions do
		local folder = fixturesState:WaitForChild(fixtureId)
		overlays[fixtureId] = buildOverlay(fixtureId)
		folder.AttributeChanged:Connect(function()
			refresh(fixtureId)
		end)
	end
	refreshAll()
end

return LuxLensController
