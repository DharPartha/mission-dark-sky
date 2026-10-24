--!strict
-- Parts: small helpers every world builder uses, plus the two color palettes
-- (cozy Byers Station and the corrupted Glarelands). Placeholder art from Roblox parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))

local Parts = {}

export type Palette = {
	grass: Color3,
	road: Color3,
	sidewalk: Color3,
	stripe: Color3,
	houseWalls: { Color3 },
	roof: Color3,
	window: Color3,
	metal: Color3,
	crossingPole: Color3,
	sign: Color3,
	wood: Color3,
	water: Color3,
	path: Color3,
}

Parts.Town = {
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
	wood = Color3.fromRGB(120, 72, 44),
	water = Color3.fromRGB(40, 70, 110),
	path = Color3.fromRGB(122, 98, 70),
} :: Palette

-- Cold blue-grey and near-black, cut by corrupted orange-red glows.
Parts.Glare = {
	grass = Color3.fromRGB(24, 26, 34),
	road = Color3.fromRGB(18, 18, 24),
	sidewalk = Color3.fromRGB(70, 72, 84),
	stripe = Color3.fromRGB(255, 120, 70),
	houseWalls = { Color3.fromRGB(60, 62, 78), Color3.fromRGB(50, 56, 72), Color3.fromRGB(70, 64, 76) },
	roof = Color3.fromRGB(30, 26, 34),
	window = Color3.fromRGB(255, 96, 54),
	metal = Color3.fromRGB(40, 40, 48),
	crossingPole = Color3.fromRGB(180, 120, 40),
	sign = Color3.fromRGB(90, 30, 30),
	wood = Color3.fromRGB(60, 40, 40),
	water = Color3.fromRGB(60, 20, 20),
	path = Color3.fromRGB(60, 50, 50),
} :: Palette

export type PartProps = {
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

function Parts.makePart(props: PartProps): Part
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

-- Models are Persistent so small, important props stay loaded when streaming is on.
function Parts.makeModel(name: string, parent: Instance, persistent: boolean?): Model
	local model = Instance.new("Model")
	model.Name = name
	if persistent ~= false then
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end
	model.Parent = parent
	return model
end

function Parts.makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- A sloped roof half. A wedge's slope faces its -Z side.
function Parts.makeWedge(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Anchored = true
	wedge.Parent = parent
	return wedge
end

-- Writes localized text on both faces of a board part.
function Parts.writeOnBoard(board: BasePart, textKey: string)
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
		label.Text = Text.get(textKey)
		label.Parent = gui
	end
end

-- A signpost: post plus a board facing `facingDegrees` (0 = text readable from +Z).
function Parts.makeSign(position: Vector3, facingDegrees: number, textKey: string, palette: Palette, parent: Instance, boardSize: Vector3?): Model
	local model = Parts.makeModel("Sign_" .. textKey, parent, false)
	local size = boardSize or Vector3.new(8, 3.4, 0.3)
	local rotation = CFrame.Angles(0, math.rad(facingDegrees), 0)
	Parts.makePart({
		name = "Post",
		size = Vector3.new(0.5, 7 + size.Y / 2, 0.5),
		cframe = CFrame.new(position + Vector3.new(0, (7 + size.Y / 2) / 2, 0)),
		color = palette.metal,
		material = Enum.Material.Metal,
		parent = model,
	})
	local board = Parts.makePart({
		name = "Board",
		size = size,
		cframe = CFrame.new(position + Vector3.new(0, 7, 0)) * rotation,
		color = palette.sign,
		parent = model,
	})
	Parts.writeOnBoard(board, textKey)
	return model
end

-- A flat strip between two ground points (roads, trails, creeks).
function Parts.strip(name: string, from: Vector3, to: Vector3, width: number, height: number, color: Color3, material: Enum.Material, parent: Instance, y: number?): Part
	local flatFrom = Vector3.new(from.X, 0, from.Z)
	local flatTo = Vector3.new(to.X, 0, to.Z)
	local length = (flatTo - flatFrom).Magnitude
	local middle = (flatFrom + flatTo) / 2 + Vector3.new(0, y or height / 2, 0)
	return Parts.makePart({
		name = name,
		size = Vector3.new(width, height, length + width * 0.5),
		cframe = CFrame.lookAt(middle, middle + (flatTo - flatFrom)),
		color = color,
		material = material,
		parent = parent,
	})
end

return Parts
