--!strict
-- HUDController: Darkness Meter, objective, side buttons, notices, the before/after
-- panel, and the settings panel. Presentation only: it reads server state attributes
-- and never changes game state (except asking for a Studio test reset).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local ExperienceConfig = require(ConfigFolder:WaitForChild("ExperienceConfig"))
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local Text = require(SharedFolder:WaitForChild("Text"))
local Net = require(SharedFolder:WaitForChild("Net"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))
local QualityController = require(script.Parent:WaitForChild("QualityController"))

local HUDController = {}

local ZONE_ID = "Leo"
local NOTICE_SECONDS = 3.5
local METER_WIDTH = 380

local state: Folder
local gui: ScreenGui
local remotes: Folder
local noticeLabel: TextLabel
local noticeToken = 0
local banner: TextLabel
local comparePanel: Frame
local compareRows: { [string]: { before: TextLabel, now: TextLabel } } = {}
local settingsPanel: Frame
local lensButton: TextButton
local devBanner: TextLabel
local lensToggleCallback: (() -> boolean)? = nil

local function formatArg(arg: any, argKind: any): any
	if argKind == "text" and typeof(arg) == "string" then
		return Text.get(arg)
	elseif argKind == "evidence" and typeof(arg) == "string" then
		local card = (MoonTipsConfig.Evidence :: any)[arg]
		return if card then Text.pick(card.title) else arg
	end
	return arg
end

function HUDController.showNotice(key: string, arg: any?, argKind: any?)
	local message = if arg ~= nil then Text.get(key, formatArg(arg, argKind)) else Text.get(key)
	noticeToken += 1
	local myToken = noticeToken
	noticeLabel.Text = message
	noticeLabel.Visible = true
	task.delay(NOTICE_SECONDS, function()
		if noticeToken == myToken then
			noticeLabel.Visible = false
		end
	end)
end

-- Telegraph banner: steady text and an icon, no flashing.
function HUDController.showBanner(key: string, seconds: number)
	banner.Text = "⚠ " .. Text.get(key)
	banner.Visible = true
	task.delay(seconds, function()
		banner.Visible = false
	end)
end

local function buildMeter()
	local meter = UiKit.panel("DarknessMeter", gui)
	meter.AnchorPoint = Vector2.new(0.5, 0)
	meter.Position = UDim2.new(0.5, 0, 0, 8)
	meter.Size = UDim2.fromOffset(METER_WIDTH, 78)
	UiKit.padding(meter, 8)

	local title = UiKit.label({
		name = "Title",
		text = Text.get("meter_label"),
		size = UDim2.new(1, 0, 0, 20),
		textSize = 16,
		bold = true,
		parent = meter,
	})
	local value = UiKit.label({
		name = "Value",
		text = "",
		size = UDim2.new(1, 0, 0, 20),
		textSize = 16,
		bold = true,
		alignX = Enum.TextXAlignment.Right,
		parent = meter,
	})

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(0, 28)
	track.Size = UDim2.new(1, 0, 0, 16)
	track.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
	track.BorderSizePixel = 0
	UiKit.corner(track, 8)
	track.Parent = meter

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BorderSizePixel = 0
	UiKit.corner(fill, 8)
	fill.Parent = track

	-- Threshold ticks (shape cue, not just color) at 25/50/75 and the restore target.
	for _, mark in { 25, 50, 75 } do
		local tick = Instance.new("Frame")
		tick.Size = UDim2.new(0, 2, 1, 4)
		tick.Position = UDim2.new(mark / 100, -1, 0, -2)
		tick.BackgroundColor3 = Color3.new(1, 1, 1)
		tick.BackgroundTransparency = 0.4
		tick.BorderSizePixel = 0
		tick.Parent = track
	end
	local goal = Instance.new("TextLabel")
	goal.Name = "Goal"
	goal.BackgroundTransparency = 1
	goal.Text = "▼"
	goal.TextColor3 = UiKit.Colors.buttonPrimary
	goal.Font = Enum.Font.GothamBold
	goal.TextSize = 14
	goal.Size = UDim2.fromOffset(14, 14)
	goal.AnchorPoint = Vector2.new(0.5, 1)
	goal.Parent = track

	local stars = UiKit.label({
		name = "Stars",
		text = "",
		size = UDim2.new(1, 0, 0, 18),
		textSize = 16,
		color = UiKit.Colors.buttonPrimary,
		parent = meter,
	})
	stars.Position = UDim2.fromOffset(0, 46)

	local function update()
		local score = state:GetAttribute(ZONE_ID .. "Score") or 0
		local threshold = state:GetAttribute(ZONE_ID .. "Threshold") or 75
		title.Text = Text.get("meter_label") .. ": " .. Text.get(DarknessMath.bandKey(score))
		value.Text = Text.get("meter_value", score)
		goal.Position = UDim2.new(threshold / 100, 0, 0, -1)
		-- Color goes from warm glare-orange to deep night blue; number and stars repeat it.
		fill.BackgroundColor3 = Color3.fromRGB(240, 140, 70):Lerp(Color3.fromRGB(90, 130, 255), score / 100)
		local tween = TweenInfo.new(if ClientSettings.get("reducedMotion") then 0 else 0.6)
		TweenService:Create(fill, tween, { Size = UDim2.fromScale(score / 100, 1) }):Play()
		local filled = math.floor(score / 25)
		stars.Text = string.rep("★ ", filled) .. string.rep("☆ ", 4 - filled)
	end
	state:GetAttributeChangedSignal(ZONE_ID .. "Score"):Connect(update)
	update()
end

local function buildObjective()
	local box = UiKit.panel("Objective", gui)
	box.Position = UDim2.fromOffset(12, 8)
	box.Size = UDim2.fromOffset(300, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	UiKit.padding(box, 10)
	UiKit.list(box, 4)
	UiKit.label({
		text = Text.get("zone_leo"),
		textSize = 14,
		color = UiKit.Colors.muted,
		autoHeight = true,
		layoutOrder = 1,
		parent = box,
	})
	local objective = UiKit.label({
		text = "",
		textSize = 18,
		bold = true,
		autoHeight = true,
		layoutOrder = 2,
		parent = box,
	})
	local function update()
		local key = state:GetAttribute("ObjectiveKey")
		local arg = state:GetAttribute("ObjectiveArg")
		if typeof(key) == "string" then
			objective.Text = if arg ~= nil then Text.get(key, arg) else Text.get(key)
		end
	end
	state:GetAttributeChangedSignal("ObjectiveKey"):Connect(update)
	state:GetAttributeChangedSignal("ObjectiveArg"):Connect(update)
	update()
end

local function buildNotices()
	noticeLabel = UiKit.label({
		name = "Notice",
		text = "",
		size = UDim2.fromOffset(460, 0),
		textSize = 18,
		bold = true,
		alignX = Enum.TextXAlignment.Center,
		autoHeight = true,
		parent = gui,
	})
	noticeLabel.AnchorPoint = Vector2.new(0.5, 0)
	noticeLabel.Position = UDim2.new(0.5, 0, 0, 96)
	noticeLabel.BackgroundTransparency = 0.15
	noticeLabel.BackgroundColor3 = UiKit.Colors.card
	noticeLabel.Visible = false
	UiKit.corner(noticeLabel, 10)
	UiKit.padding(noticeLabel, 8)

	banner = UiKit.label({
		name = "TelegraphBanner",
		text = "",
		size = UDim2.fromOffset(520, 0),
		textSize = 22,
		bold = true,
		color = UiKit.Colors.textDark,
		alignX = Enum.TextXAlignment.Center,
		autoHeight = true,
		parent = gui,
	})
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 150)
	banner.BackgroundColor3 = UiKit.Colors.buttonPrimary
	banner.BackgroundTransparency = 0
	banner.Visible = false
	UiKit.corner(banner, 10)
	UiKit.padding(banner, 10)
end

local function buildCompare()
	comparePanel = UiKit.panel("Compare", gui, 0.02)
	comparePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	comparePanel.Position = UDim2.fromScale(0.5, 0.5)
	comparePanel.Size = UDim2.fromOffset(440, 0)
	comparePanel.AutomaticSize = Enum.AutomaticSize.Y
	comparePanel.Visible = false
	comparePanel.ZIndex = 5
	UiKit.padding(comparePanel, 14)
	UiKit.list(comparePanel, 8)

	UiKit.label({ text = Text.get("compare_title"), textSize = 22, bold = true, autoHeight = true, layoutOrder = 1, parent = comparePanel })

	local function row(order: number, key: string, labelKey: string, isHeader: boolean?)
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.new(1, 0, 0, 28)
		frame.LayoutOrder = order
		frame.Parent = comparePanel
		local textSize = if isHeader then 15 else 18
		local color = if isHeader then UiKit.Colors.muted else UiKit.Colors.text
		UiKit.label({ text = Text.get(labelKey), size = UDim2.fromScale(0.5, 1), textSize = textSize, color = color, parent = frame })
		local before = UiKit.label({ text = if isHeader then Text.get("compare_before") else "", size = UDim2.fromScale(0.25, 1), textSize = textSize, color = color, bold = not isHeader, alignX = Enum.TextXAlignment.Center, parent = frame })
		before.Position = UDim2.fromScale(0.5, 0)
		local now = UiKit.label({ text = if isHeader then Text.get("compare_now") else "", size = UDim2.fromScale(0.25, 1), textSize = textSize, color = color, bold = not isHeader, alignX = Enum.TextXAlignment.Center, parent = frame })
		now.Position = UDim2.fromScale(0.75, 0)
		compareRows[key] = { before = before, now = now }
	end
	row(2, "header", "estimate_note", true)
	row(3, "Score", "compare_score")
	row(4, "Glare", "reading_glare")
	row(5, "Uplight", "reading_uplight")
	row(6, "Blue", "compare_blue")
	row(7, "Safe", "compare_safe")

	UiKit.button({
		text = Text.get("btn_close"),
		layoutOrder = 10,
		parent = comparePanel,
		onClick = ScreenManager.close,
	})
end

local function refreshCompare()
	local function pair(key: string, format: (any) -> string)
		local rowLabels = compareRows[key]
		rowLabels.before.Text = format(state:GetAttribute(ZONE_ID .. "Base" .. key))
		rowLabels.now.Text = format(state:GetAttribute(ZONE_ID .. key))
	end
	local function asTen(value: any): string
		return Text.get("reading_value_10", DarknessMath.toTen(tonumber(value) or 0))
	end
	pair("Score", function(value)
		return tostring(value or "-")
	end)
	pair("Glare", asTen)
	pair("Uplight", asTen)
	pair("Blue", asTen)
	pair("Safe", function(value)
		return if value then "✓ " .. Text.get("yes") else "✗ " .. Text.get("no")
	end)
end

function HUDController.showCompare()
	ScreenManager.open("Compare")
end

local function buildSettings()
	settingsPanel = UiKit.panel("Settings", gui, 0.02)
	settingsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsPanel.Position = UDim2.fromScale(0.5, 0.5)
	settingsPanel.Size = UDim2.fromOffset(380, 0)
	settingsPanel.AutomaticSize = Enum.AutomaticSize.Y
	UiKit.padding(settingsPanel, 14)
	UiKit.list(settingsPanel, 8)

	UiKit.label({ text = Text.get("settings_title"), textSize = 22, bold = true, autoHeight = true, layoutOrder = 1, parent = settingsPanel })

	local order = 2
	for _, setting in { { name = "reducedMotion", key = "setting_reduced_motion" }, { name = "largeText", key = "setting_large_text" }, { name = "highContrast", key = "setting_high_contrast" } } do
		local settingName = setting.name :: ClientSettings.SettingName
		local button: TextButton
		local function label(): string
			return Text.get(setting.key) .. ": " .. Text.get(if ClientSettings.get(settingName) then "setting_on" else "setting_off")
		end
		button = UiKit.button({
			text = label(),
			layoutOrder = order,
			parent = settingsPanel,
			onClick = function()
				ClientSettings.set(settingName, not ClientSettings.get(settingName))
				button.Text = label()
			end,
		})
		order += 1
	end

	local qualityButton: TextButton
	local function qualityLabel(): string
		return Text.get("quality_setting", Text.get("quality_" .. QualityController.choice()))
	end
	qualityButton = UiKit.button({
		text = qualityLabel(),
		layoutOrder = 10,
		parent = settingsPanel,
		onClick = function()
			QualityController.cycle()
			qualityButton.Text = qualityLabel()
		end,
	})

	-- Developer tools: only built when the server marks this player as a developer.
	-- The server re-checks every request; this is convenience, not protection.
	local devSection = Instance.new("Frame")
	devSection.Name = "DevTools"
	devSection.BackgroundTransparency = 1
	devSection.Size = UDim2.new(1, 0, 0, 0)
	devSection.AutomaticSize = Enum.AutomaticSize.Y
	devSection.LayoutOrder = 20
	devSection.Visible = false
	devSection.Parent = settingsPanel
	UiKit.list(devSection, 6)
	local confirmWord = state:GetAttribute("ResetConfirmWord") or ""
	UiKit.label({ text = Text.get("dev_confirm_hint", confirmWord), textSize = 14, color = UiKit.Colors.warn, autoHeight = true, layoutOrder = 1, parent = devSection })
	local confirmBox = Instance.new("TextBox")
	confirmBox.Size = UDim2.new(1, 0, 0, UiKit.ButtonHeight)
	confirmBox.BackgroundColor3 = UiKit.Colors.card
	confirmBox.TextColor3 = UiKit.Colors.text
	confirmBox.PlaceholderText = confirmWord
	confirmBox.Text = ""
	confirmBox.ClearTextOnFocus = false
	confirmBox.Font = Enum.Font.GothamBold
	confirmBox.TextSize = 18
	confirmBox.LayoutOrder = 2
	UiKit.corner(confirmBox, 10)
	confirmBox.Parent = devSection
	local devRemote = remotes:WaitForChild(Net.Remotes.DevRequest) :: RemoteEvent
	for index, action in { { key = "dev_reset_world", action = "resetWorld" }, { key = "dev_reset_profile", action = "resetProfile" } } do
		UiKit.button({
			text = Text.get(action.key),
			color = UiKit.Colors.buttonDanger,
			layoutOrder = 2 + index,
			parent = devSection,
			onClick = function()
				devRemote:FireServer(action.action, confirmBox.Text)
				confirmBox.Text = ""
				ScreenManager.close()
			end,
		})
	end

	local player = Players.LocalPlayer
	local function updateDev()
		local isDev = player:GetAttribute("DarkSkyDeveloper") == true
		devSection.Visible = isDev
		devBanner.Visible = isDev
		devBanner.Text = Text.get("dev_banner", tostring(state:GetAttribute("Environment") or "?"))
	end
	player:GetAttributeChangedSignal("DarkSkyDeveloper"):Connect(updateDev)
	updateDev()

	UiKit.label({ text = Text.get("settings_version", ExperienceConfig.Version), textSize = 13, color = UiKit.Colors.muted, autoHeight = true, layoutOrder = 30, parent = settingsPanel })
	UiKit.button({
		text = Text.get("btn_close"),
		layoutOrder = 31,
		parent = settingsPanel,
		onClick = ScreenManager.close,
	})
	ScreenManager.register("Settings", settingsPanel)
end

-- Personal status chips: Doubt Tokens and save status (both are "You", not team).
local function buildStatusChips()
	local chips = Instance.new("Frame")
	chips.Name = "StatusChips"
	chips.BackgroundTransparency = 1
	chips.AnchorPoint = Vector2.new(1, 1)
	-- Above the developer banner row at the very bottom.
	chips.Position = UDim2.new(1, -12, 1, -30)
	chips.Size = UDim2.fromOffset(300, 64)
	chips.Parent = gui
	local layout = UiKit.list(chips, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local function chip(order: number): TextLabel
		local label = UiKit.label({ text = "", size = UDim2.fromOffset(0, 26), textSize = 14, bold = true, alignX = Enum.TextXAlignment.Center, layoutOrder = order, parent = chips })
		label.AutomaticSize = Enum.AutomaticSize.X
		label.BackgroundColor3 = UiKit.Colors.card
		label.BackgroundTransparency = 0.15
		UiKit.corner(label, 8)
		UiKit.padding(label, 4)
		return label
	end
	local tokens = chip(1)
	local save = chip(2)

	task.spawn(function()
		local folder = Players.LocalPlayer:WaitForChild("DarkSkyProfile")
		local function update()
			tokens.Text = "🤔 " .. Text.get("tokens_chip", folder:GetAttribute("DoubtTokens") or 0)
			local status = tostring(folder:GetAttribute("SaveStatus") or "loading")
			local icon = if status == "loaded" or status == "new" then "💾 " else "⚠ "
			save.Text = icon .. Text.get("save_" .. status)
			save.TextColor3 = if status == "unsaved" or status == "lock_lost" then UiKit.Colors.warn else UiKit.Colors.text
		end
		folder.AttributeChanged:Connect(update)
		update()
	end)
end

local function buildSideButtons()
	local column = Instance.new("Frame")
	column.Name = "SideButtons"
	column.BackgroundTransparency = 1
	column.AnchorPoint = Vector2.new(1, 0)
	column.Position = UDim2.new(1, -12, 0, 100)
	column.Size = UDim2.fromOffset(150, 260)
	column.Parent = gui
	UiKit.list(column, 8)

	lensButton = UiKit.button({
		text = "🔍 " .. Text.get("hud_lens"),
		size = UDim2.new(1, 0, 0, 56),
		layoutOrder = 1,
		parent = column,
		onClick = function()
			if lensToggleCallback then
				local on = lensToggleCallback()
				lensButton.Text = "🔍 " .. Text.get(if on then "hud_lens_on" else "hud_lens")
				lensButton.BackgroundColor3 = if on then UiKit.Colors.buttonPrimary else UiKit.Colors.button
				lensButton.TextColor3 = if on then UiKit.Colors.textDark else UiKit.Colors.text
			end
		end,
	})
	UiKit.button({
		text = "📖 " .. Text.get("hud_journal"),
		size = UDim2.new(1, 0, 0, 56),
		layoutOrder = 2,
		parent = column,
		onClick = function()
			ScreenManager.toggle("Journal")
		end,
	})
	UiKit.button({
		text = Text.get("hud_compare"),
		size = UDim2.new(1, 0, 0, 56),
		layoutOrder = 3,
		parent = column,
		onClick = function()
			ScreenManager.toggle("Compare")
		end,
	})
	UiKit.button({
		text = "⚙ " .. Text.get("hud_settings"),
		size = UDim2.new(1, 0, 0, 56),
		layoutOrder = 4,
		parent = column,
		onClick = function()
			ScreenManager.toggle("Settings")
		end,
	})
end

-- Lux Lens controller registers here; returns the new on/off state.
function HUDController.setLensToggle(callback: () -> boolean)
	lensToggleCallback = callback
end

function HUDController.getGui(): ScreenGui
	return gui
end

function HUDController.init(screenGui: ScreenGui, stateFolder: Folder, remotesFolder: Folder)
	gui = screenGui
	state = stateFolder
	remotes = remotesFolder

	-- Red bar across the top, only for authorized developers in test environments.
	devBanner = UiKit.label({ name = "DevBanner", text = "", size = UDim2.new(1, 0, 0, 22), textSize = 14, bold = true, alignX = Enum.TextXAlignment.Center, parent = gui })
	devBanner.BackgroundColor3 = UiKit.Colors.buttonDanger
	devBanner.BackgroundTransparency = 0
	devBanner.Position = UDim2.new(0, 0, 1, -22)
	devBanner.Visible = false

	buildMeter()
	buildObjective()
	buildNotices()
	buildCompare()
	ScreenManager.register("Compare", comparePanel, refreshCompare)
	buildSettings()
	buildStatusChips()
	buildSideButtons()

	for _, key in { "Score", "Glare", "Uplight", "Blue", "Safe" } do
		state:GetAttributeChangedSignal(ZONE_ID .. key):Connect(function()
			if ScreenManager.isOpen("Compare") then
				refreshCompare()
			end
		end)
	end

	(remotes:WaitForChild(Net.Remotes.Notice) :: RemoteEvent).OnClientEvent:Connect(HUDController.showNotice);
	(remotes:WaitForChild(Net.Remotes.ShowCompare) :: RemoteEvent).OnClientEvent:Connect(HUDController.showCompare)
end

return HUDController
