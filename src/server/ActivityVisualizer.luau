local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local ZoneDefinitions = require(Shared:WaitForChild("ZoneDefinitions"))

-- Visible stand-ins for the people and vehicles the sensors report.
-- Markers are created once, then parented between the lot and hidden storage.
-- Parenting (rather than transparency) is used because avatar faces and
-- accessories are not hidden by part transparency alone.
local ActivityVisualizer = {}

local peopleMarkers: { Model } = {}
local vehicleMarkers: { Model } = {}
local peopleFolder: Folder? = nil
local vehiclesFolder: Folder? = nil
local hiddenFolder: Folder? = nil

-- Requested counts are kept unclamped so markers still appear if a scenario is
-- selected before the avatars have finished loading.
local requestedPeople = 0
local requestedVehicles = 0

local function makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	material: Enum.Material?,
	shape: Enum.PartType?,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material or Enum.Material.SmoothPlastic
	if props.shape then
		part.Shape = props.shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

local function createVehicle(index: number, position: Vector3, parent: Instance): Model
	local activity = Config.Activity
	local model = Instance.new("Model")
	model.Name = string.format("Vehicle_%d", index)
	model.Parent = parent

	local wheelRadius = activity.VehicleWheelDiameter / 2
	local bodyY = position.Y + wheelRadius + activity.VehicleBodySize.Y / 2

	local body = makePart({
		name = "Body",
		size = activity.VehicleBodySize,
		cframe = CFrame.new(position.X, bodyY, position.Z),
		color = activity.VehicleColor,
		parent = model,
	})

	-- Hood sits forward of the cabin so the shape reads as a car, not a box.
	makePart({
		name = "Hood",
		size = activity.VehicleHoodSize,
		cframe = CFrame.new(
			position.X,
			bodyY + activity.VehicleBodySize.Y / 2 + activity.VehicleHoodSize.Y / 2,
			position.Z - activity.VehicleBodySize.Z / 2 + activity.VehicleHoodSize.Z / 2 + 0.3
		),
		color = activity.VehicleColor,
		parent = model,
	})

	makePart({
		name = "Cabin",
		size = activity.VehicleCabinSize,
		cframe = CFrame.new(
			position.X,
			bodyY + activity.VehicleBodySize.Y / 2 + activity.VehicleCabinSize.Y / 2,
			position.Z + 0.6
		),
		color = activity.VehicleWindowColor,
		parent = model,
	})

	local wheelOffsetX = activity.VehicleBodySize.X / 2
	local wheelOffsetZ = activity.VehicleBodySize.Z / 2 - 1.6
	for _, offset in
		{
			Vector3.new(wheelOffsetX, 0, wheelOffsetZ),
			Vector3.new(-wheelOffsetX, 0, wheelOffsetZ),
			Vector3.new(wheelOffsetX, 0, -wheelOffsetZ),
			Vector3.new(-wheelOffsetX, 0, -wheelOffsetZ),
		}
	do
		makePart({
			name = "Wheel",
			-- Cylinder parts spin around their X axis, which is the axle here.
			size = Vector3.new(
				activity.VehicleWheelThickness,
				activity.VehicleWheelDiameter,
				activity.VehicleWheelDiameter
			),
			cframe = CFrame.new(position.X + offset.X, position.Y + wheelRadius, position.Z + offset.Z),
			color = activity.VehicleWheelColor,
			parent = model,
			shape = Enum.PartType.Cylinder,
		})
	end

	for _, side in { -1, 1 } do
		makePart({
			name = "Headlight",
			size = Vector3.new(0.9, 0.4, 0.3),
			cframe = CFrame.new(
				position.X + side * 1.4,
				bodyY + 0.2,
				position.Z - activity.VehicleBodySize.Z / 2
			),
			color = activity.VehicleHeadlightColor,
			parent = model,
			material = Enum.Material.Neon,
		})
	end

	model.PrimaryPart = body
	return model
end

local function createBlockPerson(index: number, position: Vector3, parent: Instance): Model
	local activity = Config.Activity
	local model = Instance.new("Model")
	model.Name = string.format("Person_%d", index)
	model.Parent = parent

	local bodyY = position.Y + activity.PersonBodySize.Y / 2
	local body = makePart({
		name = "Body",
		size = activity.PersonBodySize,
		cframe = CFrame.new(position.X, bodyY, position.Z),
		color = activity.PersonColor,
		parent = model,
	})

	makePart({
		name = "Head",
		size = Vector3.new(activity.PersonHeadSize, activity.PersonHeadSize, activity.PersonHeadSize),
		cframe = CFrame.new(
			position.X,
			bodyY + activity.PersonBodySize.Y / 2 + activity.PersonHeadSize / 2,
			position.Z
		),
		color = activity.PersonColor,
		parent = model,
		shape = Enum.PartType.Ball,
	})

	model.PrimaryPart = body
	return model
end

-- Yields: CreateHumanoidModelFromDescription fetches avatar assets.
local function createAvatarPerson(index: number, position: Vector3, lookAt: Vector3): Model?
	local ok, model = pcall(function()
		local description = Instance.new("HumanoidDescription")
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)

	if not ok or model == nil then
		return nil
	end

	model.Name = string.format("Person_%d", index)
	local pivot = Vector3.new(position.X, position.Y + Config.Activity.PersonPivotHeight, position.Z)
	model:PivotTo(CFrame.lookAt(pivot, Vector3.new(lookAt.X, pivot.Y, lookAt.Z)))

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	return model
end

local function applyVisibility()
	local people = peopleFolder
	local vehicles = vehiclesFolder
	local hidden = hiddenFolder
	if people == nil or vehicles == nil or hidden == nil then
		return
	end

	for index, model in peopleMarkers do
		model.Parent = if index <= requestedPeople then people else hidden
	end
	for index, model in vehicleMarkers do
		model.Parent = if index <= requestedVehicles then vehicles else hidden
	end
end

function ActivityVisualizer.build(lotFolder: Folder)
	table.clear(peopleMarkers)
	table.clear(vehicleMarkers)
	requestedPeople = 0
	requestedVehicles = 0

	local existing = lotFolder:FindFirstChild("Activity")
	if existing then
		existing:Destroy()
	end
	local existingHidden = ServerStorage:FindFirstChild("MissionDarkSkyHidden")
	if existingHidden then
		existingHidden:Destroy()
	end

	local hidden = Instance.new("Folder")
	hidden.Name = "MissionDarkSkyHidden"
	hidden.Parent = ServerStorage
	hiddenFolder = hidden

	local activityFolder = Instance.new("Folder")
	activityFolder.Name = "Activity"
	activityFolder.Parent = lotFolder

	local people = Instance.new("Folder")
	people.Name = "People"
	people.Parent = activityFolder
	peopleFolder = people

	local vehicles = Instance.new("Folder")
	vehicles.Name = "Vehicles"
	vehicles.Parent = activityFolder
	vehiclesFolder = vehicles

	local lotCenter = Config.Lot.Center
	local groundY = lotCenter.Y + Config.Lot.Size.Y / 2

	for index, offset in ZoneDefinitions.getVehicleSlots() do
		local position = Vector3.new(lotCenter.X + offset.X, groundY, lotCenter.Z + offset.Z)
		table.insert(vehicleMarkers, createVehicle(index, position, hidden))
	end

	-- Avatars yield, so build them after the lot is playable and reveal them
	-- as they finish. Counts already requested are re-applied each time.
	task.spawn(function()
		for index, offset in ZoneDefinitions.getPeopleSlots() do
			local position = Vector3.new(lotCenter.X + offset.X, groundY, lotCenter.Z + offset.Z)
			local model = nil
			if Config.Activity.UseAvatarsForPeople then
				model = createAvatarPerson(index, position, lotCenter)
			end
			if model == nil then
				model = createBlockPerson(index, position, hidden)
			else
				model.Parent = hidden
			end
			table.insert(peopleMarkers, model)
			applyVisibility()
		end
	end)

	applyVisibility()
end

function ActivityVisualizer.setCounts(people: number, vehicles: number)
	if people == requestedPeople and vehicles == requestedVehicles then
		return
	end

	requestedPeople = people
	requestedVehicles = vehicles
	applyVisibility()
end

return ActivityVisualizer
