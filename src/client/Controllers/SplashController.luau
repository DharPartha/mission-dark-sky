--!strict
-- SplashController: the opening Dark Sky splash. A deep-blue night sky with a bright moon,
-- softly twinkling stars, and the story's four constellations (Leo, Orion, Scorpius, Cetus,
-- drawn from BossConfig). The DARK SKY title appears after a short delay.
--
-- It is a background layer: its ScreenGui sits behind the game UI (lower DisplayOrder), so the
-- knowledge-check panels and HUD stay in front. It shows when the player joins and behind any
-- knowledge check, then fades out so the 3D night sky (same look) takes over during play.
-- Built only from UI shapes and text: nothing to download. Reduced motion: no twinkle, no fades.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local Text = require(Root:WaitForChild("Shared"):WaitForChild("Text"))

local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))

local SplashController = {}

-- Where each constellation sits on screen (center, as a fraction of the screen).
local CONSTELLATIONS: { { id: string, position: UDim2 } } = {
	{ id = "Leo", position = UDim2.fromScale(0.15, 0.22) },
	{ id = "Orion", position = UDim2.fromScale(0.5, 0.18) },
	{ id = "Scorpius", position = UDim2.fromScale(0.17, 0.76) },
	{ id = "Cetus", position = UDim2.fromScale(0.82, 0.76) },
}
local BOX = Vector2.new(260, 170)
local LINE_COLOR = Color3.fromRGB(150, 176, 255)
local STAR_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(214, 226, 255),
	Color3.fromRGB(255, 240, 214),
}

local gui: ScreenGui
local canvas: CanvasGroup
local title: TextLabel
local subtitle: TextLabel
local twinkles: { Tween } = {}
local twinkleTargets: { { frame: Frame, low: number, high: number, seconds: number, delay: number } } = {}
local visible = false
local titleShown = false

local function circle(name: string, size: number, color: Color3, position: UDim2, transparency: number, parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(size, size)
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

local function addTwinkle(frame: Frame, low: number, high: number, random: Random)
	table.insert(twinkleTargets, {
		frame = frame,
		low = low,
		high = high,
		seconds = random:NextNumber(Tuning.Splash.TwinkleMinSeconds, Tuning.Splash.TwinkleMaxSeconds),
		delay = random:NextNumber(0, 2),
	})
end

local function startTwinkle()
	if ClientSettings.get("reducedMotion") or #twinkles > 0 then
		return
	end
	for _, target in twinkleTargets do
		target.frame.BackgroundTransparency = target.low
		-- Slow fade up and down, forever (cancelled while the splash is hidden).
		local tween = TweenService:Create(
			target.frame,
			TweenInfo.new(target.seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, target.delay),
			{ BackgroundTransparency = target.high }
		)
		tween:Play()
		table.insert(twinkles, tween)
	end
end

local function stopTwinkle()
	for _, tween in twinkles do
		tween:Cancel()
	end
	table.clear(twinkles)
end

local function buildSky(random: Random)
	-- Deep blue gradient: near-black at the top to deep blue near the horizon.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 5, 18)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(10, 18, 52)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 38, 92)),
	})
	gradient.Parent = canvas

	-- A faint Milky Way band across the sky.
	local band = Instance.new("Frame")
	band.Name = "MilkyWay"
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.5)
	band.Size = UDim2.new(1.6, 0, 0, 220)
	band.Rotation = -24
	band.BackgroundColor3 = Color3.fromRGB(190, 200, 255)
	band.BorderSizePixel = 0
	local bandFade = Instance.new("UIGradient")
	bandFade.Rotation = 90
	bandFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 1),
	})
	bandFade.Parent = band
	band.Parent = canvas

	-- Background stars: small, some brighter, each twinkling at its own pace.
	for index = 1, Tuning.Splash.StarCount do
		local roll = random:NextNumber()
		local size = if roll > 0.95 then 4 elseif roll > 0.75 then 3 elseif roll > 0.4 then 2 else 1
		local star = circle(
			"Star" .. index,
			size,
			STAR_COLORS[random:NextInteger(1, #STAR_COLORS)],
			UDim2.fromScale(random:NextNumber(0.01, 0.99), random:NextNumber(0.01, 0.97)),
			random:NextNumber(0.05, 0.5),
			canvas
		)
		addTwinkle(star, random:NextNumber(0.0, 0.25), random:NextNumber(0.55, 0.85), random)
	end
end

local function buildMoon()
	local position = UDim2.fromScale(0.85, 0.2)
	-- Soft glow rings behind a bright, solid moon (it is never washed out).
	circle("MoonGlowOuter", 340, Color3.fromRGB(190, 200, 255), position, 0.94, canvas)
	circle("MoonGlow", 220, Color3.fromRGB(230, 232, 255), position, 0.86, canvas)
	local moon = circle("Moon", 124, Color3.fromRGB(248, 244, 224), position, 0, canvas)
	for _, crater in { { 0.32, 0.36, 22 }, { 0.62, 0.58, 30 }, { 0.42, 0.72, 14 }, { 0.7, 0.3, 12 } } do
		circle("Crater", crater[3], Color3.fromRGB(226, 220, 196), UDim2.fromScale(crater[1], crater[2]), 0.2, moon)
	end
end

local function buildConstellation(id: string, center: UDim2, random: Random)
	local boss = (BossConfig :: any)[id]
	if boss == nil then
		return
	end
	local box = Instance.new("Frame")
	box.Name = "Constellation_" .. id
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = center
	box.Size = UDim2.fromOffset(BOX.X, BOX.Y + 26)
	box.BackgroundTransparency = 1
	box.Parent = canvas

	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	for _, point in boss.starPoints do
		minU, maxU = math.min(minU, point.u), math.max(maxU, point.u)
		minV, maxV = math.min(minV, point.v), math.max(maxV, point.v)
	end
	local scale = math.min((BOX.X - 30) / math.max(maxU - minU, 1), (BOX.Y - 20) / math.max(maxV - minV, 1))
	local width = (maxU - minU) * scale
	local height = (maxV - minV) * scale
	local function at(point: { u: number, v: number }): Vector2
		-- Mirrored like a sky chart (east on the left), centered in the box.
		return Vector2.new(
			(BOX.X - width) / 2 + (maxU - point.u) * scale,
			(BOX.Y - height) / 2 + (maxV - point.v) * scale
		)
	end

	for _, pair in boss.lines do
		local a, b = at(boss.starPoints[pair[1]]), at(boss.starPoints[pair[2]])
		local delta = b - a
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
		line.Size = UDim2.fromOffset(delta.Magnitude, 2)
		line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		line.BackgroundColor3 = LINE_COLOR
		line.BackgroundTransparency = 0.45
		line.BorderSizePixel = 0
		line.Parent = box
	end
	for _, point in boss.starPoints do
		local position = at(point)
		circle("Glow", 16, Color3.fromRGB(200, 214, 255), UDim2.fromOffset(position.X, position.Y), 0.8, box)
		local star = circle("Star", 7, Color3.new(1, 1, 1), UDim2.fromOffset(position.X, position.Y), 0, box)
		addTwinkle(star, 0, 0.35, random)
	end

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, BOX.Y + 2)
	label.Size = UDim2.fromOffset(BOX.X, 22)
	label.BackgroundTransparency = 1
	label.Text = Text.get("splash_con_" .. id)
	label.TextColor3 = Color3.fromRGB(170, 186, 235)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.Parent = box
end

local function buildTitle()
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.46)
	title.Size = UDim2.new(0.9, 0, 0, 110)
	title.BackgroundTransparency = 1
	title.Text = Text.get("splash_title")
	title.TextColor3 = Color3.fromRGB(238, 242, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextTransparency = 1
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = 96
	sizeLimit.Parent = title
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(120, 150, 255)
	glow.Thickness = 2
	glow.Transparency = 1
	glow.Parent = title
	title.Parent = canvas

	subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.new(0.5, 0, 0.46, 64)
	subtitle.Size = UDim2.new(0.9, 0, 0, 30)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = Text.get("splash_subtitle")
	subtitle.TextColor3 = Color3.fromRGB(190, 200, 236)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 20
	subtitle.TextTransparency = 1
	subtitle.Parent = canvas
end

local function revealTitle()
	if titleShown then
		return
	end
	titleShown = true
	local stroke = title:FindFirstChildOfClass("UIStroke")
	if ClientSettings.get("reducedMotion") then
		title.TextTransparency = 0
		subtitle.TextTransparency = 0
		if stroke then
			stroke.Transparency = 0.6
		end
		return
	end
	TweenService:Create(title, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { TextTransparency = 0 }):Play()
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Transparency = 0.6 }):Play()
	end
	TweenService:Create(subtitle, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.8), { TextTransparency = 0 }):Play()
end

local function setVisible(show: boolean)
	if show == visible then
		return
	end
	visible = show
	local seconds = if ClientSettings.get("reducedMotion") then 0 else Tuning.Splash.FadeSeconds
	if show then
		gui.Enabled = true
		startTwinkle()
		TweenService:Create(canvas, TweenInfo.new(seconds), { GroupTransparency = 0 }):Play()
	else
		local fade = TweenService:Create(canvas, TweenInfo.new(seconds), { GroupTransparency = 1 })
		fade.Completed:Connect(function()
			if not visible then
				gui.Enabled = false
				stopTwinkle()
			end
		end)
		fade:Play()
	end
end

function SplashController.init(state: Folder)
	gui = Instance.new("ScreenGui")
	gui.Name = "DarkSkySplash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- Behind the game UI (default 0), so panels and the HUD stay in front.
	gui.DisplayOrder = -10
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	canvas = Instance.new("CanvasGroup")
	canvas.Name = "Sky"
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.BackgroundColor3 = Color3.new(1, 1, 1)
	canvas.BorderSizePixel = 0
	canvas.GroupTransparency = 0
	canvas.Parent = gui

	-- Same sky every time (fixed seed), so the splash looks designed rather than random.
	local random = Random.new(20261024)
	buildSky(random)
	buildMoon()
	for _, entry in CONSTELLATIONS do
		buildConstellation(entry.id, entry.position, random)
	end
	buildTitle()

	visible = true
	gui.Enabled = true
	startTwinkle()
	local startedAt = os.clock()
	task.delay(Tuning.Splash.TitleDelaySeconds, revealTitle)

	-- Visible at first, and behind any knowledge check; otherwise the 3D sky takes over.
	RunService.Heartbeat:Connect(function()
		local wanted = os.clock() - startedAt < Tuning.Splash.MinimumSeconds or typeof(state:GetAttribute("QuizActive")) == "string"
		if wanted and not titleShown and os.clock() - startedAt >= Tuning.Splash.TitleDelaySeconds then
			revealTitle()
		end
		setVisible(wanted)
	end)
	ClientSettings.changed:Connect(function(name: string)
		if name == "reducedMotion" then
			if ClientSettings.get("reducedMotion") then
				stopTwinkle()
			elseif visible then
				startTwinkle()
			end
		end
	end)
end

return SplashController
