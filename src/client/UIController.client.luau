local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local remotes = shared:WaitForChild("Remotes")
local commandEvent = remotes:WaitForChild("SimulationCommand")
local stateEvent = remotes:WaitForChild("SimulationState")

local COLORS = {
	panel = Color3.fromRGB(14, 20, 33),
	card = Color3.fromRGB(24, 34, 50),
	button = Color3.fromRGB(42, 66, 92),
	accent = Color3.fromRGB(105, 193, 255),
	text = Color3.fromRGB(238, 243, 250),
	muted = Color3.fromRGB(165, 178, 196),
}

local gui = Instance.new("ScreenGui")
gui.Name = "MissionDarkSkyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 16)
panel.Size = UDim2.fromOffset(390, 650)
panel.BackgroundColor3 = COLORS.panel
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function textLabel(name: string, height: number, text: string, size: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = text
	label.Parent = panel
	return label
end

local title = textLabel("Title", 26, "MISSION DARK SKY", 20, COLORS.accent)
title.Font = Enum.Font.GothamBold
textLabel("Subtitle", 18, "Make Every Light Count", 13, COLORS.muted)

local scenarioLabel = textLabel("Scenario", 36, "Scenario: connecting…", 15, COLORS.text)
scenarioLabel.Font = Enum.Font.GothamSemibold

local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Size = UDim2.new(1, 0, 0, 116)
statusCard.BackgroundColor3 = COLORS.card
statusCard.BorderSizePixel = 0
statusCard.Parent = panel
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 1, -16)
statusText.Position = UDim2.fromOffset(10, 8)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Code
statusText.TextSize = 14
statusText.TextColor3 = COLORS.text
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Text = "Waiting for server state…"
statusText.Parent = statusCard

local metricsText = textLabel("Metrics", 82, "Estimated metrics will appear here.", 13, COLORS.text)
metricsText.Font = Enum.Font.Code

local function button(parent: Instance, text: string, callback): TextButton
	local control = Instance.new("TextButton")
	control.Size = UDim2.fromOffset(82, 30)
	control.BackgroundColor3 = COLORS.button
	control.BorderSizePixel = 0
	control.Font = Enum.Font.GothamSemibold
	control.TextSize = 12
	control.TextColor3 = COLORS.text
	control.Text = text
	control.AutoButtonColor = true
	control.Parent = parent
	Instance.new("UICorner", control).CornerRadius = UDim.new(0, 6)
	control.Activated:Connect(callback)
	return control
end

local controlsTitle = textLabel("ControlsTitle", 20, "Manual controls", 14, COLORS.accent)
controlsTitle.Font = Enum.Font.GothamBold

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.Size = UDim2.new(1, 0, 0, 68)
controls.BackgroundTransparency = 1
controls.Parent = panel
local controlGrid = Instance.new("UIGridLayout")
controlGrid.CellSize = UDim2.fromOffset(82, 30)
controlGrid.CellPadding = UDim2.fromOffset(8, 6)
controlGrid.FillDirectionMaxCells = 4
controlGrid.Parent = controls

button(controls, "Person +", function()
	commandEvent:FireServer("peopleDelta", 1)
end)
button(controls, "Person −", function()
	commandEvent:FireServer("peopleDelta", -1)
end)
button(controls, "Vehicle +", function()
	commandEvent:FireServer("vehiclesDelta", 1)
end)
button(controls, "Vehicle −", function()
	commandEvent:FireServer("vehiclesDelta", -1)
end)
button(controls, "Time +1h", function()
	commandEvent:FireServer("timeDelta", 1)
end)
button(controls, "Ambient +", function()
	commandEvent:FireServer("ambientDelta", 0.1)
end)
button(controls, "Ambient −", function()
	commandEvent:FireServer("ambientDelta", -0.1)
end)
button(controls, "Toggle Event", function()
	commandEvent:FireServer("toggleEvent")
end)

local weather = Instance.new("Frame")
weather.Name = "Weather"
weather.Size = UDim2.new(1, 0, 0, 30)
weather.BackgroundTransparency = 1
weather.Parent = panel
local weatherLayout = Instance.new("UIListLayout")
weatherLayout.FillDirection = Enum.FillDirection.Horizontal
weatherLayout.Padding = UDim.new(0, 8)
weatherLayout.Parent = weather
for _, weatherName in { "Clear", "Cloudy", "Rain" } do
	button(weather, weatherName, function()
		commandEvent:FireServer("weather", weatherName)
	end)
end
button(weather, "AUTO DEMO", function()
	commandEvent:FireServer("startDemo")
end)

local scenariosTitle = textLabel("ScenariosTitle", 20, "Repeatable scenarios", 14, COLORS.accent)
scenariosTitle.Font = Enum.Font.GothamBold

local scenarios = Instance.new("ScrollingFrame")
scenarios.Name = "Scenarios"
scenarios.Size = UDim2.new(1, 0, 0, 126)
scenarios.BackgroundTransparency = 1
scenarios.BorderSizePixel = 0
scenarios.ScrollBarThickness = 4
scenarios.CanvasSize = UDim2.fromOffset(0, 126)
scenarios.Parent = panel
local scenarioGrid = Instance.new("UIGridLayout")
scenarioGrid.CellSize = UDim2.fromOffset(170, 30)
scenarioGrid.CellPadding = UDim2.fromOffset(8, 6)
scenarioGrid.FillDirectionMaxCells = 2
scenarioGrid.Parent = scenarios

local scenarioButtons = {
	{ "Empty", "empty" },
	{ "Pedestrian", "pedestrian" },
	{ "Multiple People", "multiplePedestrians" },
	{ "Vehicle", "vehicle" },
	{ "Event", "event" },
	{ "Event Ends", "eventEnds" },
	{ "Rain", "rain" },
	{ "Sunrise", "sunrise" },
}

for _, definition in scenarioButtons do
	local control = button(scenarios, definition[1], function()
		commandEvent:FireServer("scenario", definition[2])
	end)
	control.Size = UDim2.fromOffset(170, 30)
end

stateEvent.OnClientEvent:Connect(function(snapshot)
	local sensors = snapshot.sensors
	local decision = snapshot.decision
	local metrics = snapshot.metrics

	scenarioLabel.Text = "Scenario: " .. snapshot.scenarioName
	statusText.Text = string.format(
		"People: %d     Vehicles: %d\nAmbient: %.2f  Time: %05.2f\nWeather: %-6s  Event: %s\nCurrent light: %3d%%  Target: %3d%%",
		sensors.people,
		sensors.vehicles,
		sensors.ambientLight,
		sensors.timeOfDay,
		sensors.weather,
		if sensors.eventActive then "ON" else "OFF",
		math.floor(snapshot.currentLighting * 100 + 0.5),
		math.floor(decision.targetLevel * 100 + 0.5)
	)

	metricsText.Text = string.format(
		"Estimated Energy: %.2f units   Estimated Cost: %.2f units\nFixed: %.2f  Timed: %.2f  Change vs fixed: %+.1f%%\n%s  •  %s",
		metrics.estimatedEnergy,
		metrics.estimatedCost,
		metrics.fixedEnergy,
		metrics.timedEnergy,
		metrics.adaptiveChangePercent,
		metrics.safetyActivityStatus,
		metrics.environmentStatus
	)
end)
