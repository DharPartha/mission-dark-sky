--!strict
-- PledgeController: the Night Sky Pledge picker, the personal Star Card it produces, and the
-- end card. Preset choices only (no typing). Shows the safety reminder before any choice.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local PledgeConfig = require(Root:WaitForChild("Config"):WaitForChild("PledgeConfig"))
local ExperienceConfig = require(Root:WaitForChild("Config"):WaitForChild("ExperienceConfig"))
local Text = require(Root:WaitForChild("Shared"):WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

local PledgeController = {}

local SELECTED_COLOR = Color3.fromRGB(226, 170, 64)

local submitRemote: RemoteEvent
local pledgePanel: Frame
local cardPanel: Frame
local cardList: Frame
local endCard: Frame
local selections: { [string]: { [string]: boolean } } = {}
local warningLabel: TextLabel

local function actionText(category: string, actionId: string): string
	for _, action in (PledgeConfig.Actions :: any)[category] or {} do
		if action.id == actionId then
			return Text.pick(action.text)
		end
	end
	return actionId
end

local function myPledge(): { [string]: { string } }
	local folder = Players.LocalPlayer:FindFirstChild("DarkSkyProfile")
	local json = if folder then folder:GetAttribute("PledgeJson") else nil
	if typeof(json) ~= "string" then
		return {}
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
	return if ok and typeof(decoded) == "table" then decoded else {}
end

function PledgeController.hasPledged(): boolean
	return next(myPledge()) ~= nil
end

local function countSelected(category: string): number
	local count = 0
	for _ in selections[category] do
		count += 1
	end
	return count
end

local function buildPledgePanel(gui: ScreenGui)
	pledgePanel = UiKit.panel("Pledge", gui, 0.02)
	pledgePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	pledgePanel.Position = UDim2.fromScale(0.5, 0.5)
	pledgePanel.Size = UDim2.fromOffset(560, 520)
	UiKit.padding(pledgePanel, 14)

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 1, -UiKit.ButtonHeight - 10)
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 8
	scroll.Parent = pledgePanel
	UiKit.list(scroll, 8)

	UiKit.label({ text = "🌟 " .. Text.get("pledge_title"), textSize = 24, bold = true, autoHeight = true, layoutOrder = 1, parent = scroll })
	UiKit.label({ text = Text.get("pledge_intro"), textSize = 16, autoHeight = true, layoutOrder = 2, parent = scroll })
	UiKit.label({ text = "⚠ " .. Text.get("pledge_safety"), textSize = 15, bold = true, color = UiKit.Colors.warn, autoHeight = true, layoutOrder = 3, parent = scroll })

	local order = 10
	for _, category in PledgeConfig.Categories do
		selections[category] = {}
		order += 1
		UiKit.label({ text = Text.get("pledge_cat_" .. category), textSize = 18, bold = true, color = UiKit.Colors.buttonPrimary, autoHeight = true, layoutOrder = order, parent = scroll })
		for _, action in (PledgeConfig.Actions :: any)[category] do
			order += 1
			local button: TextButton
			button = UiKit.button({
				text = "☐ " .. Text.pick(action.text),
				size = UDim2.new(1, -10, 0, 52),
				textSize = 15,
				layoutOrder = order,
				parent = scroll,
				onClick = function()
					local picked = selections[category]
					if picked[action.id] then
						picked[action.id] = nil
					elseif countSelected(category) < PledgeConfig.MaxPerCategory then
						picked[action.id] = true
					end
					local on = picked[action.id] == true
					-- Checkbox shape plus color, so the choice never relies on color alone.
					button.Text = (if on then "☑ " else "☐ ") .. Text.pick(action.text)
					button.BackgroundColor3 = if on then SELECTED_COLOR else UiKit.Colors.button
					button.TextColor3 = if on then UiKit.Colors.textDark else UiKit.Colors.text
				end,
			})
		end
	end
	order += 1
	warningLabel = UiKit.label({ text = "", textSize = 15, color = UiKit.Colors.warn, autoHeight = true, layoutOrder = order, parent = scroll })

	local submit = UiKit.button({
		text = Text.get("pledge_submit"),
		color = UiKit.Colors.buttonPrimary,
		textColor = UiKit.Colors.textDark,
		size = UDim2.new(1, 0, 0, UiKit.ButtonHeight),
		parent = pledgePanel,
		onClick = function()
			local choices = {}
			for _, category in PledgeConfig.Categories do
				local list = {}
				for actionId in selections[category] do
					table.insert(list, actionId)
				end
				if #list == 0 then
					warningLabel.Text = Text.get("pledge_need_each")
					return
				end
				choices[category] = list
			end
			warningLabel.Text = ""
			submitRemote:FireServer(choices)
		end,
	})
	submit.AnchorPoint = Vector2.new(0, 1)
	submit.Position = UDim2.fromScale(0, 1)
	ScreenManager.register("Pledge", pledgePanel)
end

local function refreshCard()
	for _, child in cardList:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local pledge = myPledge()
	local order = 0
	for _, category in PledgeConfig.Categories do
		local picked = pledge[category]
		if typeof(picked) == "table" and #picked > 0 then
			order += 1
			UiKit.label({ text = Text.get("pledge_cat_" .. category), textSize = 16, bold = true, color = UiKit.Colors.buttonPrimary, autoHeight = true, layoutOrder = order, parent = cardList })
			for _, actionId in picked do
				order += 1
				UiKit.label({ text = "★ " .. actionText(category, actionId), textSize = 15, autoHeight = true, layoutOrder = order, parent = cardList })
			end
		end
	end
end

local function buildCard(gui: ScreenGui)
	cardPanel = UiKit.panel("StarCard", gui, 0)
	cardPanel.BackgroundColor3 = Color3.fromRGB(20, 26, 60)
	cardPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	cardPanel.Position = UDim2.fromScale(0.5, 0.5)
	cardPanel.Size = UDim2.fromOffset(460, 0)
	cardPanel.AutomaticSize = Enum.AutomaticSize.Y
	UiKit.padding(cardPanel, 16)
	UiKit.list(cardPanel, 8)
	UiKit.label({ text = "✦ " .. Text.get("starcard_title") .. " ✦", textSize = 24, bold = true, alignX = Enum.TextXAlignment.Center, autoHeight = true, layoutOrder = 1, parent = cardPanel })
	cardList = Instance.new("Frame")
	cardList.BackgroundTransparency = 1
	cardList.Size = UDim2.new(1, 0, 0, 0)
	cardList.AutomaticSize = Enum.AutomaticSize.Y
	cardList.LayoutOrder = 2
	cardList.Parent = cardPanel
	UiKit.list(cardList, 4)
	UiKit.label({ text = Text.get("starcard_footer"), textSize = 16, bold = true, alignX = Enum.TextXAlignment.Center, color = UiKit.Colors.buttonPrimary, autoHeight = true, layoutOrder = 3, parent = cardPanel })
	UiKit.button({ text = Text.get("btn_close"), layoutOrder = 4, parent = cardPanel, onClick = ScreenManager.close })
	ScreenManager.register("StarCard", cardPanel, refreshCard)
end

local function buildEndCard(gui: ScreenGui)
	endCard = Instance.new("Frame")
	endCard.Name = "EndCard"
	endCard.Size = UDim2.fromScale(1, 1)
	endCard.BackgroundColor3 = Color3.fromRGB(8, 10, 28)
	endCard.BackgroundTransparency = 0.08
	endCard.ZIndex = 20
	endCard.Visible = false
	endCard.Parent = gui
	local column = Instance.new("Frame")
	column.BackgroundTransparency = 1
	column.AnchorPoint = Vector2.new(0.5, 0.5)
	column.Position = UDim2.fromScale(0.5, 0.5)
	column.Size = UDim2.fromOffset(640, 0)
	column.AutomaticSize = Enum.AutomaticSize.Y
	column.ZIndex = 21
	column.Parent = endCard
	local layout = UiKit.list(column, 14)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for index, spec in { { key = "endcard_line1", size = 26 }, { key = "endcard_line2", size = 20 }, { key = "endcard_line3", size = 18 } } do
		local label = UiKit.label({ text = Text.get(spec.key), textSize = spec.size, bold = index == 1, alignX = Enum.TextXAlignment.Center, autoHeight = true, layoutOrder = index, parent = column })
		label.ZIndex = 22
	end
	local badge = UiKit.label({ text = "🏅 " .. Text.get("achievement_night_guardian"), textSize = 20, bold = true, color = UiKit.Colors.buttonPrimary, alignX = Enum.TextXAlignment.Center, autoHeight = true, layoutOrder = 5, parent = column })
	badge.ZIndex = 22
	-- Companion website instructions (also kept in the Star Journal's report screen).
	local siteUrl = ExperienceConfig.CompanionSiteUrl
	local siteLine = UiKit.label({
		text = (if siteUrl ~= "" then Text.get("report_site", siteUrl) else Text.get("report_site_missing")) .. " " .. Text.get("report_privacy"),
		textSize = 14,
		color = UiKit.Colors.muted,
		alignX = Enum.TextXAlignment.Center,
		autoHeight = true,
		layoutOrder = 7,
		parent = column,
	})
	siteLine.ZIndex = 22
	local reportButton = UiKit.button({
		text = "📝 " .. Text.get("endcard_report"),
		size = UDim2.fromOffset(300, 52),
		layoutOrder = 8,
		parent = column,
		onClick = function()
			endCard.Visible = false
			ScreenManager.open("Report")
		end,
	})
	reportButton.ZIndex = 22
	local button = UiKit.button({
		text = Text.get("endcard_continue"),
		size = UDim2.fromOffset(260, 56),
		color = UiKit.Colors.buttonPrimary,
		textColor = UiKit.Colors.textDark,
		layoutOrder = 6,
		parent = column,
		onClick = function()
			endCard.Visible = false
			ScreenManager.open("StarCard")
		end,
	})
	button.ZIndex = 22
end

function PledgeController.openStarCard()
	ScreenManager.open(if PledgeController.hasPledged() then "StarCard" else "Pledge")
end

function PledgeController.init(gui: ScreenGui, stateFolder: Folder, remote: RemoteEvent)
	submitRemote = remote
	buildPledgePanel(gui)
	buildCard(gui)
	buildEndCard(gui)

	local endCardShown = false
	local function refresh()
		if stateFolder:GetAttribute("PledgeActive") == true and not PledgeController.hasPledged() and not ScreenManager.isOpen("Pledge") then
			ScreenManager.open("Pledge")
		end
		if stateFolder:GetAttribute("EndCard") == true and not endCardShown then
			endCardShown = true
			ScreenManager.close()
			endCard.Visible = true
		end
	end
	stateFolder:GetAttributeChangedSignal("PledgeActive"):Connect(refresh)
	stateFolder:GetAttributeChangedSignal("EndCard"):Connect(refresh)
	task.spawn(function()
		local folder = Players.LocalPlayer:WaitForChild("DarkSkyProfile")
		folder:GetAttributeChangedSignal("PledgeJson"):Connect(function()
			-- Pledge saved: show the Star Card (unless the end card is about to cover it).
			if PledgeController.hasPledged() and ScreenManager.isOpen("Pledge") then
				ScreenManager.open("StarCard")
			end
		end)
		refresh()
	end)
end

return PledgeController
