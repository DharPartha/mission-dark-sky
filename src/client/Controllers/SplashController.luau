--!strict
-- SplashController: the opening Dark Sky splash.
--
-- Two looks, chosen by ExperienceConfig.SplashImageId:
--   * Artwork (id set): the owner's painted splash fills the screen, with a few stars twinkling
--     on top. If the art already contains the title, the plain night sky shows first and the
--     art fades in after the title delay, so the title still "arrives" at 2 seconds.
--   * Drawn (id ""): the same layout built from UI shapes: deep-blue sky, a bright moon in the
--     middle, Leo and Orion on the left, Scorpius and Cetus on the right (from BossConfig),
--     twinkling stars, a gold DARK SKY title, and hills with the lights of Byers Station.
--
-- It is a background layer: its ScreenGui sits behind the game UI (lower DisplayOrder), so the
-- knowledge-check panels and HUD stay in front. It shows when the player joins and behind any
-- knowledge check, then fades so the 3D night sky (same look) takes over during play.
-- Reduced motion: no twinkle, no fades.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local ExperienceConfig = require(ConfigFolder:WaitForChild("ExperienceConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local Text = require(Root:WaitForChild("Shared"):WaitForChild("Text"))

local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))

local SplashController = {}

-- Layers, back to front.
local Z = { sky = 1, stars = 2, figures = 3, moon = 3, land = 4, water = 5, town = 6, ridge = 7, title = 8, art = 10, artStars = 11, artTitle = 12 }

-- Constellation centers as screen fractions, matching the artwork's layout.
local CONSTELLATIONS: { { id: string, position: UDim2 } } = {
	{ id = "Leo", position = UDim2.fromScale(0.13, 0.21) },
	{ id = "Orion", position = UDim2.fromScale(0.31, 0.2) },
	{ id = "Scorpius", position = UDim2.fromScale(0.7, 0.2) },
	{ id = "Cetus", position = UDim2.fromScale(0.88, 0.25) },
}
-- Constellation box in pixels at a 900-pixel-tall screen (scaled to the real screen).
local BOX = Vector2.new(230, 160)
local DESIGN_HEIGHT = 900
local LINE_COLOR = Color3.fromRGB(140, 170, 255)
local GOLD = Color3.fromRGB(255, 206, 120)
local STAR_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(206, 222, 255),
	Color3.fromRGB(255, 238, 206),
}

local gui: ScreenGui
local canvas: CanvasGroup
local title: Frame
local art: ImageLabel?
local figureScales: { UIScale } = {}
local twinkles: { Tween } = {}
local twinkleTargets: { { frame: Frame, low: number, high: number, seconds: number, delay: number } } = {}
local visible = false
local titleShown = false

local function round(item: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = item
end

local function frame(name: string, props: { [string]: any }, parent: Instance): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.BorderSizePixel = 0
	for key, value in props do
		(item :: any)[key] = value
	end
	item.Parent = parent
	return item
end

-- A circle sized in pixels.
local function dot(name: string, size: number, color: Color3, position: UDim2, transparency: number, zIndex: number, parent: Instance): Frame
	local item = frame(name, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Position = position,
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		ZIndex = zIndex,
	}, parent)
	round(item)
	return item
end

-- A circle sized as a fraction of the screen height (stays round on any screen).
local function disc(name: string, heightScale: number, color: Color3, position: UDim2, transparency: number, zIndex: number, parent: Instance): Frame
	local item = frame(name, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(heightScale, heightScale),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Position = position,
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		ZIndex = zIndex,
	}, parent)
	round(item)
	return item
end

local function addTwinkle(item: Frame, low: number, high: number, random: Random)
	table.insert(twinkleTargets, {
		frame = item,
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

local function scatterStars(count: number, top: number, bottom: number, zIndex: number, random: Random)
	for index = 1, count do
		local roll = random:NextNumber()
		local size = if roll > 0.96 then 4 elseif roll > 0.8 then 3 elseif roll > 0.45 then 2 else 1
		local star = dot(
			"Star" .. index,
			size,
			STAR_COLORS[random:NextInteger(1, #STAR_COLORS)],
			UDim2.fromScale(random:NextNumber(0.01, 0.99), random:NextNumber(top, bottom)),
			random:NextNumber(0.05, 0.5),
			zIndex,
			canvas
		)
		addTwinkle(star, random:NextNumber(0, 0.25), random:NextNumber(0.55, 0.9), random)
	end
end

local function fadeEnds(item: GuiObject)
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = item
end

local function buildSky(random: Random)
	-- Near-black navy at the top to deep blue at the horizon.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 7, 22)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(10, 20, 58)),
		ColorSequenceKeypoint.new(0.68, Color3.fromRGB(28, 44, 104)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 30)),
	})
	gradient.Parent = canvas

	-- Milky Way: a soft band rising from the lower right, like the artwork.
	local band = frame("MilkyWay", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.72, 0.36),
		Size = UDim2.new(1.1, 0, 0.22, 0),
		Rotation = -28,
		BackgroundColor3 = Color3.fromRGB(170, 160, 255),
		ZIndex = Z.sky,
	}, canvas)
	local bandFade = Instance.new("UIGradient")
	bandFade.Rotation = 90
	bandFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.86),
		NumberSequenceKeypoint.new(1, 1),
	})
	bandFade.Parent = band

	scatterStars(Tuning.Splash.StarCount, 0.01, 0.66, Z.stars, random)

	-- Two faint shooting-star streaks (position x, y, rotation, length).
	for _, streak in { { 0.63, 0.08, -32, 0.09 }, { 0.17, 0.42, 30, 0.06 } } do
		local line = frame("ShootingStar", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(streak[1], streak[2]),
			Size = UDim2.new(streak[4], 0, 0, 2),
			Rotation = streak[3],
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = Z.stars,
		}, canvas)
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new(1, 0.15)
		fade.Parent = line
	end
end

local function buildMoon()
	local position = UDim2.fromScale(0.5, 0.21)
	-- Soft glow rings behind a bright, solid moon (it is never washed out).
	disc("MoonGlowOuter", 0.5, Color3.fromRGB(150, 170, 255), position, 0.93, Z.moon, canvas)
	disc("MoonGlow", 0.34, Color3.fromRGB(214, 222, 255), position, 0.84, Z.moon, canvas)
	local moon = disc("Moon", 0.24, Color3.fromRGB(240, 242, 250), position, 0, Z.moon, canvas)
	local shade = Instance.new("UIGradient")
	shade.Rotation = 35
	shade.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 206, 226))
	shade.Parent = moon
	-- Maria (darker patches): x, y, size as fractions of the moon.
	for _, patch in { { 0.3, 0.34, 0.2 }, { 0.62, 0.3, 0.14 }, { 0.58, 0.62, 0.24 }, { 0.36, 0.7, 0.12 }, { 0.75, 0.52, 0.1 } } do
		local mark = frame("Crater", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(patch[1], patch[2]),
			Size = UDim2.fromScale(patch[3], patch[3]),
			BackgroundColor3 = Color3.fromRGB(176, 182, 204),
			BackgroundTransparency = 0.45,
			ZIndex = Z.moon,
		}, moon)
		round(mark)
	end
end

local function buildConstellation(id: string, center: UDim2, random: Random)
	local boss = (BossConfig :: any)[id]
	if boss == nil then
		return
	end
	local box = frame("Constellation_" .. id, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromOffset(BOX.X, BOX.Y + 30),
		BackgroundTransparency = 1,
		ZIndex = Z.figures,
	}, canvas)
	-- Drawn in pixels at a design size, then scaled to the screen (phone to big monitor).
	local scaler = Instance.new("UIScale")
	scaler.Parent = box
	table.insert(figureScales, scaler)

	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	for _, point in boss.starPoints do
		minU, maxU = math.min(minU, point.u), math.max(maxU, point.u)
		minV, maxV = math.min(minV, point.v), math.max(maxV, point.v)
	end
	local scale = math.min((BOX.X - 24) / math.max(maxU - minU, 1), (BOX.Y - 16) / math.max(maxV - minV, 1))
	local width = (maxU - minU) * scale
	local height = (maxV - minV) * scale
	local function at(point: { u: number, v: number }): Vector2
		-- Mirrored like a sky chart (east on the left), centered in the box.
		return Vector2.new((BOX.X - width) / 2 + (maxU - point.u) * scale, (BOX.Y - height) / 2 + (maxV - point.v) * scale)
	end

	for _, pair in boss.lines do
		local a, b = at(boss.starPoints[pair[1]]), at(boss.starPoints[pair[2]])
		local delta = b - a
		frame("Line", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
			Size = UDim2.fromOffset(delta.Magnitude, 2),
			Rotation = math.deg(math.atan2(delta.Y, delta.X)),
			BackgroundColor3 = LINE_COLOR,
			BackgroundTransparency = 0.4,
			ZIndex = Z.figures,
		}, box)
	end
	for _, point in boss.starPoints do
		local position = at(point)
		local spot = UDim2.fromOffset(position.X, position.Y)
		dot("Glow", 18, Color3.fromRGB(150, 180, 255), spot, 0.78, Z.figures, box)
		local star = dot("Star", 7, Color3.new(1, 1, 1), spot, 0, Z.figures, box)
		addTwinkle(star, 0, 0.35, random)
	end

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, BOX.Y + 4)
	label.Size = UDim2.fromOffset(BOX.X, 24)
	label.BackgroundTransparency = 1
	label.Text = string.upper(Text.get("splash_con_" .. id))
	label.TextColor3 = Color3.fromRGB(226, 230, 250)
	label.Font = Enum.Font.Garamond
	label.TextSize = 20
	label.ZIndex = Z.figures
	label.Parent = box
end

local function buildLand(random: Random)
	-- Distant hills (x, top y, width), then a lake with the moon's reflection, then the town.
	for _, hill in { { 0.12, 0.66, 0.7 }, { 0.42, 0.64, 0.55 }, { 0.7, 0.65, 0.6 }, { 0.95, 0.63, 0.55 } } do
		local mound = frame("Hill", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(hill[1], hill[2]),
			Size = UDim2.fromScale(hill[3], 0.3),
			BackgroundColor3 = Color3.fromRGB(16, 26, 62),
			ZIndex = Z.land,
		}, canvas)
		round(mound)
	end
	frame("Lowland", {
		Position = UDim2.fromScale(0, 0.72),
		Size = UDim2.fromScale(1, 0.28),
		BackgroundColor3 = Color3.fromRGB(10, 16, 40),
		ZIndex = Z.land,
	}, canvas)
	local lake = frame("Lake", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.74),
		Size = UDim2.fromScale(0.62, 0.05),
		BackgroundColor3 = Color3.fromRGB(46, 70, 140),
		BackgroundTransparency = 0.2,
		ZIndex = Z.water,
	}, canvas)
	round(lake)
	local moonPath = frame("MoonPath", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.745),
		Size = UDim2.fromScale(0.08, 0.04),
		BackgroundColor3 = Color3.fromRGB(220, 228, 255),
		BackgroundTransparency = 0.3,
		ZIndex = Z.water,
	}, canvas)
	fadeEnds(moonPath)
	-- Byers Station: warm lights clustered on the right bank.
	for index = 1, 70 do
		local x = random:NextNumber(0.52, 0.9)
		local y = random:NextNumber(0.78, 0.88)
		dot("TownLight" .. index, random:NextInteger(2, 4), Color3.fromRGB(255, 196, 120), UDim2.fromScale(x, y), random:NextNumber(0, 0.4), Z.town, canvas)
	end
	-- Dark rocky foreground where the friends sit in the artwork.
	for _, rock in { { 0.2, 0.9, 0.55 }, { 0.5, 0.95, 0.5 }, { 0.85, 0.93, 0.5 } } do
		local ridge = frame("Ridge", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(rock[1], rock[2]),
			Size = UDim2.fromScale(rock[3], 0.3),
			BackgroundColor3 = Color3.fromRGB(4, 6, 16),
			ZIndex = Z.ridge,
		}, canvas)
		round(ridge)
	end
end

local function sparkle(position: UDim2, size: number, zIndex: number, parent: Instance)
	-- A four-point star: two thin crossed bars over a soft glow.
	dot("SparkleGlow", math.floor(size * 0.7), GOLD, position, 0.6, zIndex, parent)
	for _, rotation in { 0, 90 } do
		frame("SparkleRay", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(size, 2),
			Rotation = rotation,
			BackgroundColor3 = Color3.fromRGB(255, 240, 200),
			ZIndex = zIndex,
		}, parent)
	end
end

local function buildTitle(zIndex: number)
	title = frame("TitleBlock", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.2),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
	}, canvas)
	local group = Instance.new("CanvasGroup")
	group.Name = "Fade"
	group.Size = UDim2.new(1, 0, 1, 40)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	group.ZIndex = zIndex
	group.Parent = title

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.45)
	label.Size = UDim2.fromScale(1, 0.55)
	label.BackgroundTransparency = 1
	label.Text = Text.get("splash_title")
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Garamond
	label.TextScaled = true
	label.ZIndex = zIndex
	-- Gold on the left fading to moonlight white, like the artwork's lettering.
	local tint = Instance.new("UIGradient")
	tint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GOLD),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(250, 246, 236)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 214, 255)),
	})
	tint.Parent = label
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(120, 150, 255)
	glow.Thickness = 1.5
	glow.Transparency = 0.5
	glow.Parent = label
	label.Parent = group

	-- Gold rules above and below the title, each with a sparkle.
	local top = frame("RuleTop", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.new(0.34, 0, 0, 2),
		BackgroundColor3 = GOLD,
		ZIndex = zIndex,
	}, group)
	fadeEnds(top)
	local bottom = frame("RuleBottom", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.78),
		Size = UDim2.new(0.8, 0, 0, 2),
		BackgroundColor3 = GOLD,
		ZIndex = zIndex,
	}, group)
	fadeEnds(bottom)
	sparkle(UDim2.fromScale(0.5, 0.1), 26, zIndex, group)
	sparkle(UDim2.fromScale(0.5, 0.78), 34, zIndex, group)

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.fromScale(0.5, 0.84)
	subtitle.Size = UDim2.new(1, 0, 0, 28)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = Text.get("splash_subtitle")
	subtitle.TextColor3 = Color3.fromRGB(206, 214, 240)
	subtitle.Font = Enum.Font.Garamond
	subtitle.TextSize = 22
	subtitle.ZIndex = zIndex
	subtitle.Parent = group
end

local function fadeTo(target: Instance, properties: { [string]: any }, seconds: number)
	if ClientSettings.get("reducedMotion") or seconds <= 0 then
		for key, value in properties do
			(target :: any)[key] = value
		end
		return
	end
	TweenService:Create(target, TweenInfo.new(seconds, Enum.EasingStyle.Sine), properties):Play()
end

local function revealTitle()
	if titleShown then
		return
	end
	titleShown = true
	if art and ExperienceConfig.SplashImageHasTitle then
		-- The artwork carries the title: bring the whole painting in now.
		fadeTo(art, { ImageTransparency = 0 }, 1.8)
		return
	end
	local group = title:FindFirstChild("Fade")
	if group then
		fadeTo(group, { GroupTransparency = 0 }, 1.6)
	end
end

local function buildArt(imageId: string, random: Random)
	local image = Instance.new("ImageLabel")
	image.Name = "Artwork"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = imageId
	-- Crop fills any screen shape without stretching the painting.
	image.ScaleType = Enum.ScaleType.Crop
	image.ImageTransparency = if ExperienceConfig.SplashImageHasTitle then 1 else 0
	image.ZIndex = Z.art
	image.Parent = canvas
	art = image
	-- A few live stars over the painted sky, so it still twinkles.
	scatterStars(45, 0.02, 0.45, Z.artStars, random)
	-- Start loading now so it is ready by the title delay.
	task.spawn(function()
		ContentProvider:PreloadAsync({ image })
	end)
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
		fadeTo(canvas, { GroupTransparency = 0 }, seconds)
	elseif seconds <= 0 then
		canvas.GroupTransparency = 1
		gui.Enabled = false
		stopTwinkle()
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

local function updateFigureScale()
	local height = gui.AbsoluteSize.Y
	if height <= 0 then
		return
	end
	local value = math.clamp(height / DESIGN_HEIGHT, 0.45, 1.5)
	for _, scaler in figureScales do
		scaler.Scale = value
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
	buildLand(random)
	local imageId = ExperienceConfig.SplashImageId
	if typeof(imageId) == "string" and imageId ~= "" then
		buildArt(imageId, random)
	end
	-- With painted-in title art, this drawn title stays hidden under the painting.
	buildTitle(if art and not ExperienceConfig.SplashImageHasTitle then Z.artTitle else Z.title)
	updateFigureScale()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateFigureScale)

	visible = true
	gui.Enabled = true
	startTwinkle()
	local startedAt = os.clock()
	task.delay(Tuning.Splash.TitleDelaySeconds, revealTitle)

	-- Visible at first, and behind any knowledge check; otherwise the 3D sky takes over.
	RunService.Heartbeat:Connect(function()
		local wanted = os.clock() - startedAt < Tuning.Splash.MinimumSeconds or typeof(state:GetAttribute("QuizActive")) == "string"
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
