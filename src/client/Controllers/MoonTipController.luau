--!strict
-- MoonTipController: the "Doubt it!" vote panel. Shows the Moon's tip, the evidence the
-- team has found, and two preset buttons. Works with chat disabled; no free text.
-- The server counts votes and decides the outcome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local MoonTipController = {}

local state: Folder
local evidenceFolder: Folder
local voteEvent: RemoteEvent
local panel: Frame
local tipLabel: TextLabel
local evidenceList: Frame
local statusLabel: TextLabel
local myVoteLabel: TextLabel
local myVote: string? = nil

local function tipById(tipId: string): { [string]: any }?
	for _, tip in MoonTipsConfig.Tips do
		if tip.id == tipId then
			return tip :: any
		end
	end
	return nil
end

local function refreshEvidence()
	for _, child in evidenceList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local count = 0
	for key, found in evidenceFolder:GetAttributes() do
		local card = (MoonTipsConfig.Evidence :: any)[key]
		if found and card then
			count += 1
			UiKit.label({
				text = "✓ " .. Text.pick(card.title) .. ": " .. Text.pick(card.text),
				textSize = 15,
				autoHeight = true,
				layoutOrder = count,
				parent = evidenceList,
			})
		end
	end
	if count == 0 then
		UiKit.label({ text = Text.get("vote_no_evidence"), textSize = 15, color = UiKit.Colors.muted, autoHeight = true, parent = evidenceList })
	end
end

local function refreshStatus()
	local deadline = state:GetAttribute("VoteDeadline")
	local secondsLeft = if typeof(deadline) == "number" then math.max(0, math.ceil(deadline - Workspace:GetServerTimeNow())) else 0
	statusLabel.Text = Text.get("vote_status", state:GetAttribute("VotesCast") or 0, state:GetAttribute("VotersNeeded") or 1, secondsLeft)
	myVoteLabel.Text = if myVote then Text.get("vote_cast", Text.get(if myVote == "doubt" then "vote_doubt" else "vote_agree")) else ""
end

local function refreshVisibility()
	local tipId = state:GetAttribute("VoteTipId")
	local tip = if typeof(tipId) == "string" then tipById(tipId) else nil
	if tip == nil then
		panel.Visible = false
		myVote = nil
		return
	end
	local line = Text.line(tip.lineId)
	tipLabel.Text = "🌙 " .. (if line then line.text else "")
	refreshEvidence()
	refreshStatus()
	panel.Visible = true
end

local function vote(choice: string)
	myVote = choice
	voteEvent:FireServer(choice)
	refreshStatus()
end

function MoonTipController.init(gui: ScreenGui, stateFolder: Folder, remotes: { [string]: RemoteEvent })
	state = stateFolder
	evidenceFolder = stateFolder:WaitForChild("Evidence") :: Folder
	voteEvent = remotes.MoonVote

	panel = UiKit.panel("MoonTip", gui, 0.02)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.fromOffset(480, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.Visible = false
	UiKit.padding(panel, 14)
	UiKit.list(panel, 10)

	UiKit.label({ text = Text.get("vote_title"), textSize = 22, bold = true, autoHeight = true, layoutOrder = 1, parent = panel })
	tipLabel = UiKit.label({ text = "", textSize = 20, autoHeight = true, layoutOrder = 2, parent = panel })
	UiKit.label({ text = Text.get("vote_evidence"), textSize = 15, color = UiKit.Colors.muted, bold = true, autoHeight = true, layoutOrder = 3, parent = panel })

	evidenceList = Instance.new("Frame")
	evidenceList.BackgroundTransparency = 1
	evidenceList.Size = UDim2.new(1, 0, 0, 0)
	evidenceList.AutomaticSize = Enum.AutomaticSize.Y
	evidenceList.LayoutOrder = 4
	evidenceList.Parent = panel
	UiKit.list(evidenceList, 4)

	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.Size = UDim2.new(1, 0, 0, 56)
	buttons.LayoutOrder = 5
	buttons.Parent = panel
	UiKit.list(buttons, 10, true)
	UiKit.button({
		text = Text.get("vote_agree"),
		size = UDim2.new(0.5, -5, 1, 0),
		layoutOrder = 1,
		parent = buttons,
		onClick = function()
			vote("agree")
		end,
	})
	UiKit.button({
		text = "🤔 " .. Text.get("vote_doubt"),
		size = UDim2.new(0.5, -5, 1, 0),
		color = UiKit.Colors.buttonPrimary,
		textColor = UiKit.Colors.textDark,
		layoutOrder = 2,
		parent = buttons,
		onClick = function()
			vote("doubt")
		end,
	})

	myVoteLabel = UiKit.label({ text = "", textSize = 15, autoHeight = true, layoutOrder = 6, parent = panel })
	statusLabel = UiKit.label({ text = "", textSize = 14, color = UiKit.Colors.muted, autoHeight = true, layoutOrder = 7, parent = panel })

	state:GetAttributeChangedSignal("VoteTipId"):Connect(refreshVisibility)
	state:GetAttributeChangedSignal("VotesCast"):Connect(refreshStatus)
	evidenceFolder.AttributeChanged:Connect(function()
		if panel.Visible then
			refreshEvidence()
		end
	end)
	refreshVisibility()

	-- Countdown tick.
	task.spawn(function()
		while true do
			task.wait(1)
			if panel.Visible then
				refreshStatus()
			end
		end
	end)
end

return MoonTipController
