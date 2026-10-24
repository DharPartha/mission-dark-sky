--!strict
-- SkyDomeController: the story's four constellations (Leo, Orion, Scorpius, Cetus) hung in the
-- night sky above Byers Station, so the splash sky carries on during play. Each one is faint
-- until its realm is restored (State.<Zone>Restored), then shines in its restored color.
-- Hidden in the Glarelands, where the guardians themselves fill the sky.
-- Client-only decoration under the camera: no collisions, no shadows, never streamed out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))

local NavigationController = require(script.Parent:WaitForChild("NavigationController"))

local SkyDomeController = {}

-- Compass bearing (degrees) of each constellation as seen from the town center.
local PLACEMENT: { { id: string, bearing: number } } = {
	{ id = "Leo", bearing = 40 },
	{ id = "Orion", bearing = 130 },
	{ id = "Scorpius", bearing = 220 },
	{ id = "Cetus", bearing = 310 },
}
local TOWN_CENTER = Vector3.zero
local FAINT_COLOR = Color3.fromRGB(196, 206, 235)
local LINE_THICKNESS = 0.9

type Figure = { zoneId: string, restoredColor: Color3, stars: { Part }, lines: { Part } }

local folder: Folder
local figures: { Figure } = {}

local function skyPart(name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Parent = folder
	return part
end

local function buildFigure(id: string, bearing: number): Figure?
	local boss = (BossConfig :: any)[id]
	if boss == nil then
		return nil
	end
	local sky = Tuning.TownSky
	local angle = math.rad(bearing)
	local center = TOWN_CENTER + Vector3.new(math.sin(angle) * sky.Distance, sky.Height, math.cos(angle) * sky.Distance)
	-- Same layout math as the guardians in SkyBuilder: u grows toward the viewer's left.
	local look = Vector3.new(center.X - TOWN_CENTER.X, 0, center.Z - TOWN_CENTER.Z).Unit
	local right = look:Cross(Vector3.yAxis)
	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	for _, point in boss.starPoints do
		minU, maxU = math.min(minU, point.u), math.max(maxU, point.u)
		minV, maxV = math.min(minV, point.v), math.max(maxV, point.v)
	end
	local midU, midV = (minU + maxU) / 2, (minV + maxV) / 2
	local function at(point: { u: number, v: number }): Vector3
		return center + Vector3.yAxis * (point.v - midV) * sky.GridScale - right * (point.u - midU) * sky.GridScale
	end

	local figure: Figure = { zoneId = boss.zoneId, restoredColor = boss.restoredColor, stars = {}, lines = {} }
	for starName, point in boss.starPoints do
		local star = skyPart(id .. "_" .. starName, Vector3.one * sky.StarSize, CFrame.new(at(point)), Enum.PartType.Ball)
		table.insert(figure.stars, star)
	end
	for _, pair in boss.lines do
		local a, b = at(boss.starPoints[pair[1]]), at(boss.starPoints[pair[2]])
		local line = skyPart(id .. "_Line", Vector3.new(LINE_THICKNESS, LINE_THICKNESS, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b))
		table.insert(figure.lines, line)
	end
	return figure
end

local function paint(figure: Figure, state: Folder, inTown: boolean)
	local restored = state:GetAttribute(figure.zoneId .. "Restored") == true
	local faint = Tuning.TownSky.FaintTransparency
	for _, star in figure.stars do
		star.Color = if restored then figure.restoredColor else FAINT_COLOR
		star.Transparency = if not inTown then 1 elseif restored then 0 else faint
	end
	for _, line in figure.lines do
		line.Color = if restored then figure.restoredColor else FAINT_COLOR
		-- Lines stay softer than stars so the figure reads as a chart, not a neon sign.
		line.Transparency = if not inTown then 1 elseif restored then 0.45 else math.min(faint + 0.18, 0.95)
	end
end

local function paintAll(state: Folder)
	local inTown = NavigationController.region() ~= "Glarelands"
	for _, figure in figures do
		paint(figure, state, inTown)
	end
end

function SkyDomeController.init(state: Folder)
	folder = Instance.new("Folder")
	folder.Name = "DarkSkyTownConstellations"
	folder.Parent = Workspace.CurrentCamera
	for _, entry in PLACEMENT do
		local figure = buildFigure(entry.id, entry.bearing)
		if figure then
			table.insert(figures, figure)
		end
	end
	paintAll(state)
	state.AttributeChanged:Connect(function(name: string)
		if string.sub(name, -8) == "Restored" then
			paintAll(state)
		end
	end)
	NavigationController.regionChanged:Connect(function()
		paintAll(state)
	end)
end

return SkyDomeController
