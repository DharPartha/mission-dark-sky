--!strict
-- ReportController: the community proposal screen. The player picks a restored place, a
-- recommendation, and a reflection (preset buttons, no typing). The report is built on this
-- device from the player's own journal and pledge, shown in a selectable box to copy, and
-- pasted into the companion website to print a PDF. The text never goes to the server; only
-- an anonymous "report created" count does.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local ExperienceConfig = require(ConfigFolder:WaitForChild("ExperienceConfig"))
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local ReportConfig = require(ConfigFolder:WaitForChild("ReportConfig"))
local ReportBuilder = require(SharedFolder:WaitForChild("ReportBuilder"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

local ReportController = {}

local SELECTED_COLOR = Color3.fromRGB(226, 170, 64)

local panel: Frame
local body: ScrollingFrame
local generatedRemote: RemoteEvent
local choice = { place = nil :: string?, recommendation = nil :: string?, reflection = nil :: string? }

local function decode(value: any, fallback: any): any
	if typeof(value) ~= "string" then
		return fallback
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, value)
	return if ok and typeof(decoded) == "table" then decoded else fallback
end

local function profileData(): ({ { [string]: any } }, { [string]: { string } }, { [string]: boolean })
	local folder = Players.LocalPlayer:FindFirstChild("DarkSkyProfile")
	if folder == nil then
		return {}, {}, {}
	end
	local journalValue = folder:FindFirstChild("JournalJson")
	local journal = decode(if journalValue and journalValue:IsA("StringValue") then journalValue.Value else nil, {})
	local pledge = decode(folder:GetAttribute("PledgeJson"), {})
	local restored = {}
	for zoneId in string.gmatch(tostring(folder:GetAttribute("RestoredZones") or ""), "[^,]+") do
		restored[zoneId] = true
	end
	return journal, pledge, restored
end

local function clearBody()
	for _, child in body:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local render: () -> ()

-- A row of option buttons; the chosen one shows a filled marker and color.
local function optionGroup(order: number, titleKey: string, options: { { id: string, label: string } }, selected: string?, onPick: (string) -> ()): number
	order += 1
	UiKit.label({ text = Text.get(titleKey), textSize = 17, bold = true, color = UiKit.Colors.buttonPrimary, autoHeight = true, layoutOrder = order, parent = body })
	for _, option in options do
		order += 1
		local on = option.id == selected
		UiKit.button({
			text = (if on then "◉ " else "○ ") .. option.label,
			size = UDim2.new(1, -10, 0, 50),
			textSize = 15,
			color = if on then SELECTED_COLOR else UiKit.Colors.button,
			textColor = if on then UiKit.Colors.textDark else UiKit.Colors.text,
			layoutOrder = order,
			parent = body,
			onClick = function()
				onPick(option.id)
				render()
			end,
		})
	end
	return order
end

local function showReport(text: string)
	clearBody()
	UiKit.label({ text = Text.get("report_copy_help"), textSize = 15, bold = true, autoHeight = true, layoutOrder = 1, parent = body })
	local siteUrl = ExperienceConfig.CompanionSiteUrl
	UiKit.label({
		text = if siteUrl ~= "" then Text.get("report_site", siteUrl) else Text.get("report_site_missing"),
		textSize = 15,
		autoHeight = true,
		layoutOrder = 2,
		parent = body,
	})
	UiKit.label({ text = Text.get("report_privacy"), textSize = 14, color = UiKit.Colors.muted, autoHeight = true, layoutOrder = 3, parent = body })
	-- Read-only but selectable, so players can copy it (Roblox games cannot write to the clipboard).
	local box = Instance.new("TextBox")
	box.Name = "ReportText"
	box.Size = UDim2.new(1, -10, 0, 0)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.BackgroundColor3 = Color3.fromRGB(245, 245, 240)
	box.TextColor3 = Color3.fromRGB(20, 20, 30)
	box.Font = Enum.Font.Code
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.TextWrapped = true
	box.MultiLine = true
	box.ClearTextOnFocus = false
	box.TextEditable = false
	box.Text = text
	box.LayoutOrder = 4
	UiKit.corner(box, 6)
	UiKit.padding(box, 8)
	box.Parent = body
	UiKit.button({ text = Text.get("btn_close"), layoutOrder = 5, parent = body, onClick = ScreenManager.close })
end

render = function()
	clearBody()
	local journal, pledge, restored = profileData()
	local places = ReportBuilder.availablePlaces(restored)
	if #places == 0 then
		UiKit.label({ text = Text.get("report_none_yet"), textSize = 16, autoHeight = true, layoutOrder = 1, parent = body })
		UiKit.button({ text = Text.get("btn_close"), layoutOrder = 2, parent = body, onClick = ScreenManager.close })
		return
	end
	if choice.place == nil or table.find(places, choice.place) == nil then
		choice.place = places[#places]
		choice.recommendation = nil
	end

	local order = 0
	local placeOptions = {}
	for _, placeId in places do
		local zone = (FixtureConfig.Zones :: any)[placeId]
		table.insert(placeOptions, { id = placeId, label = if zone then Text.get(zone.nameKey) else placeId })
	end
	order = optionGroup(order, "report_pick_place", placeOptions, choice.place, function(id)
		if choice.place ~= id then
			choice.recommendation = nil
		end
		choice.place = id
	end)

	local place = (ReportConfig.Places :: any)[choice.place]
	local recommendationOptions = {}
	for _, recommendation in place.recommendations do
		table.insert(recommendationOptions, { id = recommendation.id, label = Text.pick(recommendation.text) })
	end
	order = optionGroup(order, "report_pick_recommendation", recommendationOptions, choice.recommendation, function(id)
		choice.recommendation = id
	end)

	local reflectionOptions = {}
	for _, reflection in ReportConfig.Reflections do
		table.insert(reflectionOptions, { id = reflection.id, label = Text.pick(reflection.text) })
	end
	order = optionGroup(order, "report_pick_reflection", reflectionOptions, choice.reflection, function(id)
		choice.reflection = id
	end)

	local warning = UiKit.label({ text = "", textSize = 15, color = UiKit.Colors.warn, autoHeight = true, layoutOrder = order + 1, parent = body })
	UiKit.button({
		text = Text.get("report_create"),
		color = UiKit.Colors.buttonPrimary,
		textColor = UiKit.Colors.textDark,
		layoutOrder = order + 2,
		parent = body,
		onClick = function()
			if choice.place == nil or choice.recommendation == nil or choice.reflection == nil then
				warning.Text = Text.get("report_need_choices")
				return
			end
			local text = ReportBuilder.build({
				placeId = choice.place :: string,
				recommendationId = choice.recommendation :: string,
				reflectionId = choice.reflection :: string,
				journal = journal,
				pledge = pledge,
			})
			if text then
				generatedRemote:FireServer()
				showReport(text)
			end
		end,
	})
end

function ReportController.open()
	ScreenManager.open("Report")
end

function ReportController.init(gui: ScreenGui, remote: RemoteEvent)
	generatedRemote = remote
	panel = UiKit.panel("Report", gui, 0.02)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(600, 540)
	UiKit.padding(panel, 14)
	UiKit.label({ text = "📝 " .. Text.get("report_title"), size = UDim2.new(1, 0, 0, 30), textSize = 22, bold = true, parent = panel })

	body = Instance.new("ScrollingFrame")
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(0, 40)
	body.Size = UDim2.new(1, 0, 1, -40)
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollBarThickness = 8
	body.Parent = panel
	UiKit.list(body, 6)

	ScreenManager.register("Report", panel, render)
end

return ReportController
