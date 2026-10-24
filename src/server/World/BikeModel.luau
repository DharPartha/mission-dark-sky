--!strict
-- BikeModel: a simple placeholder bicycle (frame, wheels, seat, handlebars) with the
-- responsible headlamp the spec asks for: warm color, shielded, aimed down at the path.
-- Parts are massless and non-colliding; BikeService welds the model to the rider.

local Parts = require(script.Parent:WaitForChild("Parts"))

local BikeModel = {}

-- Warm (about 2700K-looking) headlamp color.
local HEADLAMP_COLOR = Color3.fromRGB(255, 196, 130)

-- Offsets are relative to the rider's HumanoidRootPart (forward is -Z). An R15 root sits
-- about 3 studs above the ground, so wheels (radius 1.2) at -1.85 touch the ground.
function BikeModel.create(frameColor: Color3): Model
	local model = Instance.new("Model")
	model.Name = "Bike"
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?): Part
		local part = Parts.makePart({
			name = name,
			size = size,
			cframe = offset,
			color = color,
			material = Enum.Material.Metal,
			shape = shape,
			canCollide = false,
			parent = model,
		})
		part.Anchored = false
		part.Massless = true
		part.CanQuery = false
		part.CanTouch = false
		part:SetAttribute("BikeOffset", offset)
		return part
	end

	local dark = Color3.fromRGB(30, 30, 34)
	local root = piece("Frame", Vector3.new(0.4, 0.4, 4), CFrame.new(0, -1.0, 0), frameColor)
	piece("Down", Vector3.new(0.35, 1.6, 0.35), CFrame.new(0, -1.6, -1.2) * CFrame.Angles(math.rad(-20), 0, 0), frameColor)
	-- Cylinders run along X, which is the wheel axle direction.
	piece("FrontWheel", Vector3.new(0.3, 2.4, 2.4), CFrame.new(0, -1.85, -2.1), dark, Enum.PartType.Cylinder)
	piece("BackWheel", Vector3.new(0.3, 2.4, 2.4), CFrame.new(0, -1.85, 2.1), dark, Enum.PartType.Cylinder)
	piece("Seat", Vector3.new(0.8, 0.25, 1.1), CFrame.new(0, -0.65, 0.9), dark)
	piece("Handlebar", Vector3.new(2, 0.2, 0.2), CFrame.new(0, -0.1, -1.7), dark)

	local lamp = piece("Headlamp", Vector3.new(0.5, 0.4, 0.4), CFrame.new(0, -0.5, -2.05), HEADLAMP_COLOR)
	lamp.Material = Enum.Material.Neon
	piece("LampShield", Vector3.new(0.65, 0.12, 0.6), CFrame.new(0, -0.25, -2.05), dark)
	local spot = Instance.new("SpotLight")
	-- Front face points forward; tilting the lamp down aims the beam at the path.
	spot.Face = Enum.NormalId.Front
	spot.Angle = 50
	spot.Range = 26
	spot.Brightness = 1.6
	spot.Color = HEADLAMP_COLOR
	spot.Shadows = false
	spot.Parent = lamp
	lamp:SetAttribute("BikeOffset", CFrame.new(0, -0.5, -2.05) * CFrame.Angles(math.rad(-25), 0, 0))

	model.PrimaryPart = root
	return model
end

return BikeModel
