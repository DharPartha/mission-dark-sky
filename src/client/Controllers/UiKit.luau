--!strict
-- UiKit: small helpers so every panel and button looks the same, has large touch targets,
-- and follows the Large Text and High Contrast settings.

local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))

local UiKit = {}

UiKit.Colors = {
	panel = Color3.fromRGB(14, 18, 34),
	card = Color3.fromRGB(28, 34, 58),
	button = Color3.fromRGB(46, 62, 104),
	buttonPrimary = Color3.fromRGB(226, 170, 64),
	buttonDanger = Color3.fromRGB(150, 60, 60),
	text = Color3.fromRGB(240, 242, 255),
	textDark = Color3.fromRGB(24, 20, 14),
	muted = Color3.fromRGB(170, 178, 210),
	good = Color3.fromRGB(120, 210, 150),
	warn = Color3.fromRGB(255, 170, 90),
	stroke = Color3.fromRGB(110, 130, 200),
}

-- Minimum touch target height (studs of screen pixels before UIScale).
UiKit.ButtonHeight = 48

local scaledLabels: { [TextLabel | TextButton]: number } = {}
local panels: { [GuiObject]: number } = {}
local strokes: { UIStroke } = {}

local function applyTextScale(label: TextLabel | TextButton, baseSize: number)
	label.TextSize = math.floor(baseSize * ClientSettings.textScale() + 0.5)
end

local function applyContrast()
	local high = ClientSettings.get("highContrast")
	for panel, baseTransparency in panels do
		if panel.Parent then
			panel.BackgroundTransparency = if high then 0 else baseTransparency
		end
	end
	for _, stroke in strokes do
		stroke.Color = if high then Color3.new(1, 1, 1) else UiKit.Colors.stroke
		stroke.Thickness = if high then 2 else 1
	end
end

ClientSettings.changed:Connect(function(name: string)
	if name == "largeText" then
		for label, baseSize in scaledLabels do
			if label.Parent then
				applyTextScale(label, baseSize)
			else
				scaledLabels[label] = nil
			end
		end
	elseif name == "highContrast" then
		applyContrast()
	end
end)

function UiKit.corner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
end

function UiKit.padding(parent: Instance, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
end

function UiKit.list(parent: Instance, spacing: number?, horizontal: boolean?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, spacing or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.Parent = parent
	return layout
end

function UiKit.panel(name: string, parent: Instance, transparency: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = UiKit.Colors.panel
	frame.BorderSizePixel = 0
	local baseTransparency = transparency or 0.08
	frame.BackgroundTransparency = baseTransparency
	panels[frame] = baseTransparency
	UiKit.corner(frame, 12)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	table.insert(strokes, stroke)
	frame.Parent = parent
	applyContrast()
	return frame
end

function UiKit.label(props: {
	name: string?,
	text: string,
	size: UDim2?,
	textSize: number?,
	color: Color3?,
	bold: boolean?,
	alignX: Enum.TextXAlignment?,
	autoHeight: boolean?,
	layoutOrder: number?,
	parent: Instance,
}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name or "Label"
	label.BackgroundTransparency = 1
	label.Text = props.text
	label.TextWrapped = true
	label.RichText = false
	label.Font = if props.bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.TextColor3 = props.color or UiKit.Colors.text
	label.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
	label.Size = props.size or UDim2.new(1, 0, 0, 24)
	if props.autoHeight then
		label.AutomaticSize = Enum.AutomaticSize.Y
	end
	label.LayoutOrder = props.layoutOrder or 0
	local baseSize = props.textSize or 18
	scaledLabels[label] = baseSize
	applyTextScale(label, baseSize)
	label.Parent = props.parent
	return label
end

function UiKit.button(props: {
	name: string?,
	text: string,
	size: UDim2?,
	color: Color3?,
	textColor: Color3?,
	textSize: number?,
	layoutOrder: number?,
	parent: Instance,
	onClick: () -> (),
}): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Text = props.text
	button.Font = Enum.Font.GothamBold
	button.TextWrapped = true
	button.AutoButtonColor = true
	button.BackgroundColor3 = props.color or UiKit.Colors.button
	button.TextColor3 = props.textColor or UiKit.Colors.text
	button.Size = props.size or UDim2.new(1, 0, 0, UiKit.ButtonHeight)
	button.LayoutOrder = props.layoutOrder or 0
	button.BorderSizePixel = 0
	UiKit.corner(button, 10)
	local baseSize = props.textSize or 18
	scaledLabels[button] = baseSize
	applyTextScale(button, baseSize)
	button.Activated:Connect(props.onClick)
	button.Parent = props.parent
	return button
end

-- Scales the whole UI down on small screens so panels fit phones.
function UiKit.attachScreenScale(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = workspace.CurrentCamera
	local function update()
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(math.min(viewport.X / 1100, viewport.Y / 720), 0.62, 1.15)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
end

return UiKit
