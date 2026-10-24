--!strict
-- NavigationController: which region the local player is in (Byers Station or the
-- Glarelands), and the guide beam the server turns on over a destination when the team
-- needs help finding it. Presentation only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config"):WaitForChild("WorldConfig"))

local NavigationController = {}

local region = "Town"
local regionEvent = Instance.new("BindableEvent")
NavigationController.regionChanged = regionEvent.Event

function NavigationController.region(): string
	return region
end

local beacon: Part? = nil

local function showBeacon(targetId: string?)
	if beacon then
		beacon:Destroy()
		beacon = nil
	end
	local trigger = if targetId then (WorldConfig.Triggers :: any)[targetId] else nil
	if trigger == nil then
		return
	end
	-- A tall, soft, warm column visible from far away (no flashing).
	local part = Instance.new("Part")
	part.Name = "GuideBeam"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 220, 150)
	part.Transparency = 0.55
	part.Size = Vector3.new(3, 160, 3)
	part.CFrame = CFrame.new(trigger.position + Vector3.new(0, 80, 0))
	part.Parent = Workspace.CurrentCamera
	beacon = part
end

function NavigationController.init(stateFolder: Folder)
	stateFolder:GetAttributeChangedSignal("BeaconTarget"):Connect(function()
		showBeacon(stateFolder:GetAttribute("BeaconTarget"))
	end)
	-- The reach is done once the server clears ReachTarget; hide the beam then too.
	stateFolder:GetAttributeChangedSignal("ReachTarget"):Connect(function()
		if stateFolder:GetAttribute("ReachTarget") == nil then
			showBeacon(nil)
		end
	end)
	showBeacon(stateFolder:GetAttribute("BeaconTarget"))

	local glare = WorldConfig.Regions.Glarelands
	RunService.Heartbeat:Connect(function()
		local character = Players.LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			local x = rootPart.Position.X
			local now = if x >= glare.minX and x <= glare.maxX then "Glarelands" else "Town"
			if now ~= region then
				region = now
				regionEvent:Fire(region)
			end
		end
	end)
end

return NavigationController
