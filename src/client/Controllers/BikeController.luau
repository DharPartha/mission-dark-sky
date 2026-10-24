--!strict
-- BikeController: bike input and buttons. The server decides everything (unlock, where
-- riding is allowed, speeds); this only sends requests and brakes locally.
--   PC:      R ride/get off, Shift boost, Space brake (while riding), B bell
--   Gamepad: L1 ride/get off, R2 boost, L2 brake, D-pad up bell
--   Touch:   large on-screen buttons with safe spacing

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local BikeController = {}

local player = Players.LocalPlayer
local request: RemoteEvent
local savedSpeed: number? = nil

local function riding(): boolean
	return player:GetAttribute("Riding") == true
end

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function setBrake(down: boolean)
	local h = humanoid()
	if h == nil then
		return
	end
	if down and riding() and savedSpeed == nil then
		savedSpeed = h.WalkSpeed
		h.WalkSpeed = 0
	elseif not down and savedSpeed ~= nil then
		h.WalkSpeed = savedSpeed
		savedSpeed = nil
	end
end

local function bindRideKeys(active: boolean)
	if active then
		-- High priority so Space brakes instead of jumping while riding.
		ContextActionService:BindActionAtPriority("DarkSkyBrake", function(_, state)
			setBrake(state == Enum.UserInputState.Begin)
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonL2)
		ContextActionService:BindAction("DarkSkyBoost", function(_, state)
			if state == Enum.UserInputState.Begin then
				request:FireServer("boost")
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR2)
		ContextActionService:BindAction("DarkSkyBell", function(_, state)
			if state == Enum.UserInputState.Begin then
				request:FireServer("bell")
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.B, Enum.KeyCode.DPadUp)
	else
		ContextActionService:UnbindAction("DarkSkyBrake")
		ContextActionService:UnbindAction("DarkSkyBoost")
		ContextActionService:UnbindAction("DarkSkyBell")
		setBrake(false)
	end
end

function BikeController.init(gui: ScreenGui, remote: RemoteEvent)
	request = remote

	local bar = Instance.new("Frame")
	bar.Name = "BikeButtons"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 12, 0.55, 0)
	bar.Size = UDim2.fromOffset(120, 280)
	bar.Visible = false
	bar.Parent = gui
	UiKit.list(bar, 10)

	local rideButton = UiKit.button({
		text = "🚲 " .. Text.get("bike_ride"),
		size = UDim2.new(1, 0, 0, 60),
		color = UiKit.Colors.buttonPrimary,
		textColor = UiKit.Colors.textDark,
		layoutOrder = 1,
		parent = bar,
		onClick = function()
			request:FireServer("toggle")
		end,
	})
	local boostButton = UiKit.button({
		text = "⚡ " .. Text.get("bike_boost"),
		size = UDim2.new(1, 0, 0, 60),
		layoutOrder = 2,
		parent = bar,
		onClick = function()
			request:FireServer("boost")
		end,
	})
	local brakeButton = UiKit.button({
		text = "✋ " .. Text.get("bike_brake"),
		size = UDim2.new(1, 0, 0, 60),
		layoutOrder = 3,
		parent = bar,
		onClick = function() end,
	})
	-- Brake is held, not tapped.
	brakeButton.MouseButton1Down:Connect(function()
		setBrake(true)
	end)
	brakeButton.MouseButton1Up:Connect(function()
		setBrake(false)
	end)
	brakeButton.MouseLeave:Connect(function()
		setBrake(false)
	end)
	local bellButton = UiKit.button({
		text = "🔔 " .. Text.get("bike_bell"),
		size = UDim2.new(1, 0, 0, 60),
		layoutOrder = 4,
		parent = bar,
		onClick = function()
			request:FireServer("bell")
		end,
	})

	ContextActionService:BindAction("DarkSkyRide", function(_, state)
		if state == Enum.UserInputState.Begin and bar.Visible then
			request:FireServer("toggle")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonL1)

	local function update()
		local folder = player:FindFirstChild("DarkSkyProfile")
		local unlocks = if folder then tostring(folder:GetAttribute("Unlocks") or "") else ""
		bar.Visible = string.find(unlocks, ",bike,", 1, true) ~= nil
		local isRiding = riding()
		rideButton.Text = if isRiding then "🚶 " .. Text.get("bike_dismount") else "🚲 " .. Text.get("bike_ride")
		boostButton.Visible = isRiding
		brakeButton.Visible = isRiding
		bellButton.Visible = isRiding
		bindRideKeys(isRiding)
	end
	player:GetAttributeChangedSignal("Riding"):Connect(update)
	task.spawn(function()
		local folder = player:WaitForChild("DarkSkyProfile")
		folder:GetAttributeChangedSignal("Unlocks"):Connect(update)
		update()
	end)
	player.CharacterAdded:Connect(function()
		savedSpeed = nil
		update()
	end)
end

return BikeController
