--!strict
-- BubbleRenderer: comic dialogue bubbles in four styles (speech, shout, thought, narration).
--
-- * Friends nearby speak in world bubbles (BillboardGui) over their heads. If you are far
--   away, their line shows in the on-screen stack instead, so nobody misses it.
-- * Narrator, Moon, and Leo always use the on-screen stack (ScreenGui).
-- * Typewriter reveal; tap a bubble to finish it, tap again to skip ahead; auto-advance.
-- * Paused while Leo's roar telegraph is showing. Reduced motion shows text instantly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local BubbleTheme = require(ConfigFolder:WaitForChild("BubbleTheme"))
local Text = require(SharedFolder:WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))

local BubbleRenderer = {}

-- Friends farther than this (studs) speak in the on-screen stack instead of over their heads.
local WORLD_BUBBLE_RANGE = 45

local stack: Frame
local queue: { Text.DialogueLine } = {}
local running = false
local pausedUntil = 0
local skipRequested = false

local function styleFor(styleName: string): { [string]: any }
	return (BubbleTheme.Styles :: any)[styleName] or BubbleTheme.Styles.speech
end

local function fontFor(style: { [string]: any }): Font
	return Font.new(
		"rbxasset://fonts/families/GothamSSm.json",
		Enum.FontWeight.Medium,
		if style.italic then Enum.FontStyle.Italic else Enum.FontStyle.Normal
	)
end

local function npcHead(speaker: string): BasePart?
	local world = Workspace:FindFirstChild("DarkSkyWorld")
	local friends = world and world:FindFirstChild("Friends")
	local npc = friends and friends:FindFirstChild(speaker)
	local head = npc and npc:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

local function isNear(part: BasePart): boolean
	local character = Players.LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart == nil or not rootPart:IsA("BasePart") then
		return false
	end
	return (rootPart.Position - part.Position).Magnitude <= WORLD_BUBBLE_RANGE
end

-- Builds one bubble. Returns the clickable root and the text label inside it.
local function makeBubble(line: Text.DialogueLine, width: number): (TextButton, TextLabel)
	local style = styleFor(line.style)
	local bubble = Instance.new("TextButton")
	bubble.Name = "Bubble_" .. line.id
	bubble.Text = ""
	bubble.AutoButtonColor = false
	bubble.BackgroundColor3 = style.background
	bubble.Size = UDim2.fromOffset(width, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	UiKit.corner(bubble, if line.style == "thought" then 22 else 12)
	UiKit.padding(bubble, 10)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = style.stroke
	stroke.Thickness = style.strokeThickness
	stroke.Parent = bubble
	UiKit.list(bubble, 2)

	if line.displayName ~= "" then
		local name = UiKit.label({
			name = "Speaker",
			text = line.displayName,
			textSize = BubbleTheme.TextSize - 4,
			color = style.stroke,
			bold = true,
			autoHeight = true,
			layoutOrder = 1,
			parent = bubble,
		})
		name.Size = UDim2.new(1, 0, 0, 0)
	end
	local body = UiKit.label({
		name = "Body",
		text = line.text,
		textSize = BubbleTheme.TextSize,
		color = style.text,
		autoHeight = true,
		layoutOrder = 2,
		parent = bubble,
	})
	body.Size = UDim2.new(1, 0, 0, 0)
	body.FontFace = fontFor(style)
	if line.style == "shout" then
		body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
	end
	return bubble, body
end

local function fadeOlderBubbles()
	local bubbles = {}
	for _, child in stack:GetChildren() do
		if child:IsA("TextButton") then
			table.insert(bubbles, child)
		end
	end
	table.sort(bubbles, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	-- Keep at most MaxVisible bubbles; dim all but the newest.
	while #bubbles > BubbleTheme.MaxVisible do
		table.remove(bubbles, 1):Destroy()
	end
	for index, bubble in bubbles do
		bubble.BackgroundTransparency = if index == #bubbles then 0 else 0.35
	end
end

local layoutCounter = 0

local function waitSeconds(seconds: number)
	-- Counts only unpaused time, and stops early when the player taps to skip.
	local elapsed = 0
	while elapsed < seconds and not skipRequested do
		local dt = RunService.Heartbeat:Wait()
		if os.clock() >= pausedUntil then
			elapsed += dt
		end
	end
end

local function showLine(line: Text.DialogueLine)
	local head = if line.world then npcHead(line.speaker) else nil
	local useWorld = head ~= nil and isNear(head :: BasePart)
	local bubble: TextButton
	local body: TextLabel
	local billboard: BillboardGui? = nil

	if useWorld then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "DarkSkyBubble"
		billboard.Size = UDim2.fromOffset(280, 120)
		billboard.StudsOffset = Vector3.new(0, 3.2, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = WORLD_BUBBLE_RANGE + 10
		billboard.Adornee = head
		billboard.ResetOnSpawn = false
		billboard.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		bubble, body = makeBubble(line, 280)
		bubble.AnchorPoint = Vector2.new(0.5, 1)
		bubble.Position = UDim2.fromScale(0.5, 1)
		bubble.Parent = billboard
	else
		bubble, body = makeBubble(line, 520)
		layoutCounter += 1
		bubble.LayoutOrder = layoutCounter
		bubble.Parent = stack
		fadeOlderBubbles()
	end

	skipRequested = false
	local typing = true
	bubble.Activated:Connect(function()
		if typing then
			typing = false
			body.MaxVisibleGraphemes = -1
		else
			skipRequested = true
		end
	end)

	local length = utf8.len(line.text) or #line.text
	if ClientSettings.get("reducedMotion") then
		body.MaxVisibleGraphemes = -1
		typing = false
	else
		body.MaxVisibleGraphemes = 0
		local shown = 0
		while typing and shown < length do
			local dt = RunService.Heartbeat:Wait()
			if os.clock() >= pausedUntil then
				shown = math.min(length, shown + dt * BubbleTheme.CharactersPerSecond)
				body.MaxVisibleGraphemes = math.floor(shown)
			end
		end
		body.MaxVisibleGraphemes = -1
		typing = false
	end

	skipRequested = false
	waitSeconds(BubbleTheme.HoldSecondsBase + length * BubbleTheme.HoldSecondsPerCharacter)

	if billboard then
		billboard:Destroy()
	end
	-- Screen bubbles stay (dimmed) until pushed out by newer ones or the queue empties.
end

local function run()
	if running then
		return
	end
	running = true
	while #queue > 0 do
		showLine(table.remove(queue, 1) :: Text.DialogueLine)
	end
	running = false
	-- Clear the stack a moment after the conversation ends.
	task.delay(2, function()
		if not running and #queue == 0 then
			for _, child in stack:GetChildren() do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
		end
	end)
end

function BubbleRenderer.enqueue(lineIds: { string })
	for _, lineId in lineIds do
		local line = Text.line(lineId)
		if line then
			table.insert(queue, line)
		end
	end
	task.spawn(run)
end

-- Holds typing and auto-advance (used during boss telegraphs).
function BubbleRenderer.pause(seconds: number)
	pausedUntil = math.max(pausedUntil, os.clock() + seconds)
end

function BubbleRenderer.init(gui: ScreenGui, dialogueEvent: RemoteEvent)
	stack = Instance.new("Frame")
	stack.Name = "DialogueStack"
	stack.BackgroundTransparency = 1
	stack.AnchorPoint = Vector2.new(0.5, 1)
	stack.Position = UDim2.new(0.5, 0, 1, -24)
	stack.Size = UDim2.fromOffset(520, 320)
	stack.Parent = gui
	local layout = UiKit.list(stack, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	dialogueEvent.OnClientEvent:Connect(function(lineIds: any)
		if typeof(lineIds) == "table" then
			BubbleRenderer.enqueue(lineIds)
		end
	end)
end

return BubbleRenderer
