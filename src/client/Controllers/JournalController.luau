--!strict
-- JournalController: the personal Star Journal panel. Reads this player's journal from
-- Player.DarkSkyProfile.JournalJson (written by the server) and lists entries by section.
-- Everything shown is simulated game evidence and is labelled that way.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

local JournalController = {}

local SECTIONS = { "realm", "evidence", "moonTip" }

local panel: Frame
local list: ScrollingFrame
local journalValue: StringValue? = nil

local function entryText(entry: { [string]: any }): string?
	if entry.kind == "realm" then
		local zone = (FixtureConfig.Zones :: any)[entry.key]
		local name = if zone then Text.get(zone.nameKey) else entry.key
		local data = entry.data or {}
		return "★ " .. Text.get("journal_realm_entry", name, data.before or 0, data.after or 0)
	elseif entry.kind == "evidence" then
		local card = (MoonTipsConfig.Evidence :: any)[entry.key]
		if card == nil then
			return nil
		end
		return "✓ " .. Text.pick(card.title) .. ": " .. Text.pick(card.text)
	elseif entry.kind == "moonTip" then
		local tipLine = nil
		for _, tip in MoonTipsConfig.Tips do
			if tip.id == entry.key then
				tipLine = Text.line(tip.lineId)
			end
		end
		local correct = entry.data and entry.data.correct
		return string.format(
			"🌙 \"%s\" — %s",
			if tipLine then tipLine.text else entry.key,
			Text.get(if correct then "journal_tip_correct" else "journal_tip_incorrect")
		)
	end
	return nil
end

local function refresh()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local entries = {}
	if journalValue then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, journalValue.Value)
		if ok and typeof(decoded) == "table" then
			entries = decoded
		end
	end

	local order = 0
	local any = false
	for _, section in SECTIONS do
		local lines = {}
		for _, entry in entries do
			if typeof(entry) == "table" and entry.kind == section then
				local textLine = entryText(entry)
				if textLine then
					table.insert(lines, textLine)
				end
			end
		end
		if #lines > 0 then
			any = true
			order += 1
			UiKit.label({ text = Text.get("journal_section_" .. section), textSize = 16, bold = true, color = UiKit.Colors.buttonPrimary, autoHeight = true, layoutOrder = order, parent = list })
			for _, textLine in lines do
				order += 1
				UiKit.label({ text = textLine, textSize = 16, autoHeight = true, layoutOrder = order, parent = list })
			end
		end
	end
	if not any then
		UiKit.label({ text = Text.get("journal_empty"), textSize = 16, color = UiKit.Colors.muted, autoHeight = true, parent = list })
	end
end

function JournalController.init(gui: ScreenGui)
	panel = UiKit.panel("Journal", gui, 0.02)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(520, 460)
	UiKit.padding(panel, 14)

	UiKit.label({ text = "📖 " .. Text.get("journal_title"), size = UDim2.new(1, 0, 0, 30), textSize = 24, bold = true, parent = panel })
	local subtitle = UiKit.label({ text = Text.get("journal_subtitle"), size = UDim2.new(1, 0, 0, 20), textSize = 14, color = UiKit.Colors.muted, parent = panel })
	subtitle.Position = UDim2.fromOffset(0, 32)

	list = Instance.new("ScrollingFrame")
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 60)
	list.Size = UDim2.new(1, 0, 1, -60 - UiKit.ButtonHeight - 10)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 8
	list.Parent = panel
	UiKit.list(list, 6)

	local close = UiKit.button({
		text = Text.get("btn_close"),
		size = UDim2.new(1, 0, 0, UiKit.ButtonHeight),
		parent = panel,
		onClick = ScreenManager.close,
	})
	close.AnchorPoint = Vector2.new(0, 1)
	close.Position = UDim2.fromScale(0, 1)

	ScreenManager.register("Journal", panel, refresh)

	task.spawn(function()
		local folder = Players.LocalPlayer:WaitForChild("DarkSkyProfile")
		journalValue = folder:WaitForChild("JournalJson") :: StringValue
		(journalValue :: StringValue).Changed:Connect(function()
			if ScreenManager.isOpen("Journal") then
				refresh()
			end
		end)
	end)
end

return JournalController
