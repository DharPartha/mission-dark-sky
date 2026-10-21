local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local ZoneDefinitions = require(Shared:WaitForChild("ZoneDefinitions"))

local ParkingLotBuilder = {}

local ROOT_NAME = "MissionDarkSky"
local LOT_NAME = "ParkingLot"

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	anchored: boolean?,
	transparency: number?,
	canCollide: boolean?,
	parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material
	part.Anchored = if props.anchored == nil then true else props.anchored
	part.Transparency = props.transparency or 0
	part.CanCollide = if props.canCollide == nil then true else props.canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

-- Demo night so the four lamps read as lights. This is not a weather simulation.
function ParkingLotBuilder.applyDemoNight()
	local scene = Config.Scene
	Lighting.ClockTime = scene.ClockTime
	Lighting.Brightness = scene.Brightness
	Lighting.Ambient = scene.Ambient
	Lighting.OutdoorAmbient = scene.OutdoorAmbient
	Lighting.FogEnd = 600
end

local function clearPreviousLot()
	local root = Workspace:FindFirstChild(ROOT_NAME)
	if root then
		root:Destroy()
	end
end

local function addStallLines(ground: Folder, lotCenter: Vector3, lotSize: Vector3)
	-- A few painted lines so the slab reads as a parking lot, not a full city.
	local stallWidth = 10
	local lineThickness = 0.2
	local lineLength = 16
	local y = lotCenter.Y + lotSize.Y / 2 + 0.05
	local startX = -20
	for index = 0, 4 do
		local x = startX + index * stallWidth
		makePart({
			name = "StallLine_" .. tostring(index + 1),
			size = Vector3.new(lineThickness, 0.1, lineLength),
			cframe = CFrame.new(lotCenter.X + x, y, lotCenter.Z),
			color = Color3.fromRGB(230, 230, 220),
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			parent = ground,
		})
	end
end

local function addFixture(fixturesFolder: Folder, fixtureId: string, offset: Vector3, lotCenter: Vector3)
	local lot = Config.Lot
	local poleHeight = lot.PoleHeight
	local poleThickness = lot.PoleThickness
	local groundY = lotCenter.Y + Config.Lot.Size.Y / 2
	local poleCenter = Vector3.new(
		lotCenter.X + offset.X,
		groundY + poleHeight / 2,
		lotCenter.Z + offset.Z
	)

	local model = Instance.new("Model")
	model.Name = fixtureId
	model.Parent = fixturesFolder

	local pole = makePart({
		name = "Pole",
		size = Vector3.new(poleThickness, poleHeight, poleThickness),
		cframe = CFrame.new(poleCenter),
		color = Color3.fromRGB(55, 55, 62),
		material = Enum.Material.Metal,
		parent = model,
	})

	local lamp = makePart({
		name = "Lamp",
		size = lot.LampSize,
		cframe = CFrame.new(poleCenter.X, groundY + poleHeight + lot.LampSize.Y / 2, poleCenter.Z),
		color = Color3.fromRGB(240, 230, 180),
		material = Enum.Material.Neon,
		parent = model,
	})
	lamp:SetAttribute("FixtureId", fixtureId)
	lamp:SetAttribute("Enabled", true)
	lamp:SetAttribute("CurrentLevel", 0)
	lamp:SetAttribute("TargetLevel", 0)

	local light = Instance.new("PointLight")
	light.Name = fixtureId
	light.Brightness = 0
	light.Range = Config.Lighting.PointLightRangeAtMin
	light.Color = Color3.fromRGB(255, 236, 200)
	light.Shadows = false
	light.Parent = lamp

	model.PrimaryPart = pole
	return lamp
end

function ParkingLotBuilder.build(): Folder
	clearPreviousLot()
	ParkingLotBuilder.applyDemoNight()

	local zone = ZoneDefinitions.getParkingLot()
	local lotSize = Config.Lot.Size
	local lotCenter = Config.Lot.Center

	local root = Instance.new("Folder")
	root.Name = ROOT_NAME
	root.Parent = Workspace

	local lotFolder = Instance.new("Folder")
	lotFolder.Name = LOT_NAME
	lotFolder.Parent = root

	local ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = lotFolder

	-- Surrounding ground so a place without a Baseplate does not read as empty void.
	makePart({
		name = "GroundPlane",
		size = Vector3.new(Config.Lot.GroundPlaneSize, 1, Config.Lot.GroundPlaneSize),
		cframe = CFrame.new(lotCenter.X, lotCenter.Y - 0.5, lotCenter.Z),
		color = Color3.fromRGB(46, 54, 44),
		material = Enum.Material.Grass,
		parent = ground,
	})

	-- Guarantees a usable spawn even in a place with no Baseplate.
	if Workspace:FindFirstChildWhichIsA("SpawnLocation", true) == nil then
		local spawnPad = Instance.new("SpawnLocation")
		spawnPad.Name = "LotSpawn"
		spawnPad.Size = Vector3.new(6, 1, 6)
		spawnPad.CFrame = CFrame.new(
			lotCenter.X,
			lotCenter.Y + lotSize.Y / 2 + 0.5,
			lotCenter.Z + lotSize.Z / 2 + 3
		)
		spawnPad.Anchored = true
		spawnPad.Color = Color3.fromRGB(90, 130, 170)
		spawnPad.Material = Enum.Material.SmoothPlastic
		spawnPad.Parent = ground
	end

	makePart({
		name = "Asphalt",
		size = lotSize,
		cframe = CFrame.new(lotCenter),
		color = Color3.fromRGB(62, 62, 68),
		material = Enum.Material.Asphalt,
		parent = ground,
	})

	-- Driveway along the -Z edge of the lot.
	makePart({
		name = "Driveway",
		size = Vector3.new(18, lotSize.Y, 16),
		cframe = CFrame.new(lotCenter.X, lotCenter.Y, lotCenter.Z - lotSize.Z / 2 - 8),
		color = Color3.fromRGB(72, 72, 78),
		material = Enum.Material.Asphalt,
		parent = ground,
	})

	-- Pedestrian strip along the +Z edge.
	makePart({
		name = "Pedestrian",
		size = Vector3.new(lotSize.X, 0.4, 6),
		cframe = CFrame.new(lotCenter.X, lotCenter.Y + lotSize.Y / 2 + 0.15, lotCenter.Z + lotSize.Z / 2 + 3),
		color = Color3.fromRGB(150, 150, 148),
		material = Enum.Material.Concrete,
		parent = ground,
	})

	addStallLines(ground, lotCenter, lotSize)

	local fixturesFolder = Instance.new("Folder")
	fixturesFolder.Name = "Fixtures"
	fixturesFolder.Parent = lotFolder

	for _, fixture in zone.fixtures do
		addFixture(fixturesFolder, fixture.id, fixture.offset, lotCenter)
	end

	local debugFolder = Instance.new("Folder")
	debugFolder.Name = "Debug"
	debugFolder.Parent = lotFolder

	if Config.Debug.ShowZoneVolume then
		makePart({
			name = "ZoneVolume",
			size = Vector3.new(lotSize.X, 20, lotSize.Z),
			cframe = CFrame.new(lotCenter.X, lotCenter.Y + 10, lotCenter.Z),
			color = Color3.fromRGB(80, 160, 255),
			material = Enum.Material.SmoothPlastic,
			transparency = 0.88,
			canCollide = false,
			parent = debugFolder,
		})
	end

	local statusPart = makePart({
		name = "StatusPart",
		size = Vector3.new(6, 3, 0.4),
		cframe = CFrame.new(lotCenter.X, lotCenter.Y + 8, lotCenter.Z + lotSize.Z / 2 + 6),
		color = Color3.fromRGB(20, 20, 24),
		material = Enum.Material.SmoothPlastic,
		canCollide = false,
		parent = debugFolder,
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusGui"
	billboard.Size = UDim2.fromOffset(280, 80)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = statusPart

	local label = Instance.new("TextLabel")
	label.Name = "StatusLabel"
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.TextWrapped = true
	label.Text = zone.displayName .. "\ncurrent 0%  target 0%"
	label.Parent = billboard

	return lotFolder
end

return ParkingLotBuilder
