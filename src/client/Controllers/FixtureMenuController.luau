--!strict
-- FixtureMenuController: the accessible list menu opened by a fixture's Inspect prompt.
-- Shows Lux Lens readings (game estimates) and one row of large buttons per verb:
-- QUESTION, SHIELD, AIM, DIM, TIME, WARM, plus Undo. Buttons only send requests;
-- the server validates and explains every result with a notice.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local FixtureMenuController = {}

local panel: ScrollingFrame
local fixturesState: Folder
local actionEvent: RemoteEvent
local openFixtureId: string? = nil
local attributeConnection: RBXScriptConnection? = nil
local readingLabels: { [string]: TextLabel } = {}
local needLabel: TextLabel
local titleLabel: TextLabel
local shieldButton: TextButton? = nil
local verbRows: { [string]: Frame } = {}

local definitions: { [string]: { [string]: any } } = {}
for _, zone in FixtureConfig.Zones do
	for _, def in zone.fixtures do
		definitions[def.id] = def :: any
	end
end

local function send(verb: string, option: string)
	if openFixtureId then
		actionEvent:FireServer(openFixtureId, verb, option)
	end
end

local function refresh()
	local fixtureId = openFixtureId
	if fixtureId == nil then
		return
	end
	local def = definitions[fixtureId]
	local folder = fixturesState:FindFirstChild(fixtureId)
	if def == nil or folder == nil then
		return
	end

	titleLabel.Text = Text.get(def.nameKey)
	needLabel.Text = if folder:GetAttribute("Questioned") then "• " .. Text.get("need_" .. def.need) else "? " .. Text.get("need_unknown")
	needLabel.TextColor3 = if def.need == "Required" and folder:GetAttribute("Questioned") then UiKit.Colors.warn else UiKit.Colors.muted

	local on = folder:GetAttribute("On") == true
	local function ten(name: string): string
		return Text.get("reading_value_10", DarknessMath.toTen(folder:GetAttribute(name) or 0))
	end
	readingLabels.brightness.Text = Text.get("reading_brightness") .. ": "
		.. (if on then Text.get("reading_percent", math.floor((folder:GetAttribute("Brightness") or 0) * 100 + 0.5)) else Text.get("status_off"))
	readingLabels.glare.Text = Text.get("reading_glare") .. ": " .. ten("Glare")
	readingLabels.uplight.Text = Text.get("reading_uplight") .. ": " .. ten("Uplight")
	readingLabels.color.Text = Text.get("reading_color") .. ": " .. Text.get("reading_kelvin", folder:GetAttribute("ColorTempK") or 0)
	readingLabels.aim.Text = Text.get("reading_aim") .. ": " .. Text.get("aim_" .. tostring(folder:GetAttribute("Aim")))
	readingLabels.schedule.Text = Text.get("reading_schedule") .. ": " .. Text.get("schedule_" .. tostring(folder:GetAttribute("Schedule")))
	readingLabels.shield.Text = Text.get("reading_shield") .. ": " .. Text.get(if folder:GetAttribute("Shielded") then "shield_yes" else "shield_no")

	if shieldButton then
		shieldButton.Text = Text.get(if folder:GetAttribute("Shielded") then "btn_shield_remove" else "btn_shield_add")
	end
	for verb, row in verbRows do
		row.Visible = table.find(def.allowedVerbs, verb) ~= nil
	end
end

local function close()
	openFixtureId = nil
	panel.Visible = false
	if attributeConnection then
		attributeConnection:Disconnect()
		attributeConnection = nil
	end
end

function FixtureMenuController.open(fixtureId: string)
	local folder = fixturesState:FindFirstChild(fixtureId)
	if definitions[fixtureId] == nil or folder == nil then
		return
	end
	if attributeConnection then
		attributeConnection:Disconnect()
	end
	openFixtureId = fixtureId
	attributeConnection = folder.AttributeChanged:Connect(refresh)
	refresh()
	panel.CanvasPosition = Vector2.zero
	panel.Visible = true
end

local function verbRow(verb: string, order: number, buttons: { { textKey: string, option: string } }): Frame
	local section = Instance.new("Frame")
	section.Name = verb
	section.BackgroundTransparency = 1
	section.Size = UDim2.new(1, 0, 0, 0)
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.LayoutOrder = order
	section.Parent = panel
	UiKit.list(section, 4)
	UiKit.label({ text = Text.get("verb_" .. verb), textSize = 14, color = UiKit.Colors.muted, bold = true, autoHeight = true, layoutOrder = 1, parent = section })

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, UiKit.ButtonHeight)
	row.LayoutOrder = 2
	row.Parent = section
	UiKit.list(row, 6, true)
	local width = 1 / #buttons
	for index, spec in buttons do
		local button = UiKit.button({
			text = Text.get(spec.textKey),
			size = UDim2.new(width, -6 * (#buttons - 1) / #buttons, 1, 0),
			layoutOrder = index,
			parent = row,
			onClick = function()
				send(verb, spec.option)
			end,
		})
		if verb == "SHIELD" then
			shieldButton = button
		end
	end
	verbRows[verb] = section
	return section
end

local function build(gui: ScreenGui)
	panel = Instance.new("ScrollingFrame")
	panel.Name = "FixtureMenu"
	panel.Position = UDim2.fromOffset(12, 110)
	panel.Size = UDim2.fromOffset(340, 470)
	panel.CanvasSize = UDim2.new()
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.ScrollBarThickness = 8
	panel.BackgroundColor3 = UiKit.Colors.panel
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Visible = false
	UiKit.corner(panel, 12)
	UiKit.padding(panel, 12)
	UiKit.list(panel, 8)
	panel.Parent = gui

	titleLabel = UiKit.label({ text = "", textSize = 22, bold = true, autoHeight = true, layoutOrder = 1, parent = panel })
	needLabel = UiKit.label({ text = "", textSize = 16, autoHeight = true, layoutOrder = 2, parent = panel })

	local readings = UiKit.panel("Readings", panel, 0)
	readings.BackgroundColor3 = UiKit.Colors.card
	readings.Size = UDim2.new(1, 0, 0, 0)
	readings.AutomaticSize = Enum.AutomaticSize.Y
	readings.LayoutOrder = 3
	UiKit.padding(readings, 8)
	UiKit.list(readings, 2)
	UiKit.label({ text = "🔍 " .. Text.get("menu_readings"), textSize = 15, bold = true, autoHeight = true, layoutOrder = 0, parent = readings })
	for index, name in { "brightness", "glare", "uplight", "color", "aim", "schedule", "shield" } do
		readingLabels[name] = UiKit.label({ text = "", textSize = 16, autoHeight = true, layoutOrder = index, parent = readings })
	end
	UiKit.label({ text = Text.get("estimate_note"), textSize = 12, color = UiKit.Colors.muted, autoHeight = true, layoutOrder = 20, parent = readings })

	verbRow("QUESTION", 10, { { textKey = "btn_ask", option = "ask" }, { textKey = "btn_off", option = "off" } })
	verbRow("SHIELD", 11, { { textKey = "btn_shield_add", option = "toggle" } })
	verbRow("AIM", 12, { { textKey = "btn_aim_down", option = "down" }, { textKey = "btn_aim_up", option = "up" } })
	verbRow("DIM", 13, { { textKey = "btn_dim_down", option = "down" }, { textKey = "btn_dim_up", option = "up" } })
	verbRow("TIME", 14, { { textKey = "btn_time_next", option = "next" } })
	verbRow("WARM", 15, { { textKey = "btn_warmer", option = "warmer" }, { textKey = "btn_cooler", option = "cooler" } })

	local footer = Instance.new("Frame")
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1, 0, 0, UiKit.ButtonHeight)
	footer.LayoutOrder = 30
	footer.Parent = panel
	UiKit.list(footer, 6, true)
	UiKit.button({
		text = "↶ " .. Text.get("btn_undo"),
		size = UDim2.new(0.5, -3, 1, 0),
		layoutOrder = 1,
		parent = footer,
		onClick = function()
			send("UNDO", "last")
		end,
	})
	UiKit.button({
		text = Text.get("btn_close"),
		size = UDim2.new(0.5, -3, 1, 0),
		color = UiKit.Colors.card,
		layoutOrder = 2,
		parent = footer,
		onClick = close,
	})
end

function FixtureMenuController.init(gui: ScreenGui, stateFolder: Folder, remotes: { [string]: RemoteEvent })
	fixturesState = stateFolder:WaitForChild("Fixtures") :: Folder
	actionEvent = remotes.FixtureAction
	build(gui)
	remotes.OpenFixtureMenu.OnClientEvent:Connect(function(fixtureId: any)
		if typeof(fixtureId) == "string" then
			FixtureMenuController.open(fixtureId)
		end
	end)

	-- Close the menu when the player walks away from the light.
	RunService.Heartbeat:Connect(function()
		local fixtureId = openFixtureId
		if fixtureId == nil then
			return
		end
		local character = Players.LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local def = definitions[fixtureId]
		if rootPart and rootPart:IsA("BasePart") and def then
			local offset = rootPart.Position - def.position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude > Tuning.Interact.MenuCloseDistance then
				close()
			end
		end
	end)
end

return FixtureMenuController
