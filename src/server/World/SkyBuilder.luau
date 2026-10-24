--!strict
-- SkyBuilder: Leo's constellation creature (star points + beams + glaring eyes) and the
-- Moon character (one per region, so she watches over both worlds).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossConfig = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config"):WaitForChild("BossConfig"))
local Parts = require(script.Parent:WaitForChild("Parts"))

local SkyBuilder = {}

export type LeoParts = {
	stars: { BasePart },
	beams: { Beam },
	eyes: { BasePart },
}

export type MoonParts = {
	body: BasePart,
	glow: BasePart,
	glintEye: BasePart,
}

function SkyBuilder.buildLeo(folder: Instance): LeoParts
	local boss = BossConfig.Leo
	local model = Parts.makeModel("Leo", folder)
	local stars: { BasePart } = {}
	local beams: { Beam } = {}
	local attachments: { [string]: Attachment } = {}

	local function starPosition(u: number, v: number): Vector3
		-- Lion faces the players' right (+Z) as they look east down the lane.
		return boss.panelCenter + Vector3.new(0, (v - 6) * boss.gridScale, -(u - 10) * boss.gridScale)
	end

	for starName, point in boss.starPoints do
		local star = Parts.makePart({
			name = starName,
			size = Vector3.new(5, 5, 5),
			shape = Enum.PartType.Ball,
			cframe = CFrame.new(starPosition(point.u, point.v)),
			color = boss.corruptedColor,
			material = Enum.Material.Neon,
			canCollide = false,
			parent = model,
		})
		star.CastShadow = false
		local attachment = Instance.new("Attachment")
		attachment.Parent = star
		attachments[starName] = attachment
		table.insert(stars, star)
	end

	for _, pair in boss.lines do
		local beam = Instance.new("Beam")
		beam.Attachment0 = attachments[pair[1]]
		beam.Attachment1 = attachments[pair[2]]
		beam.Width0 = 1.2
		beam.Width1 = 1.2
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Color = ColorSequence.new(boss.corruptedColor)
		beam.Transparency = NumberSequence.new(0.3)
		beam.Parent = model
		table.insert(beams, beam)
	end

	-- Glaring eyes near the sickle (head). They vanish when Leo is calmed.
	local eyes: { BasePart } = {}
	for _, offset in { Vector3.new(-4, 2, 3), Vector3.new(-4, 2, -3) } do
		local eye = Parts.makePart({
			name = "Eye",
			size = Vector3.new(3, 3, 3),
			shape = Enum.PartType.Ball,
			cframe = CFrame.new(starPosition(1, 9) + offset),
			color = Color3.fromRGB(255, 60, 30),
			material = Enum.Material.Neon,
			canCollide = false,
			parent = model,
		})
		table.insert(eyes, eye)
	end

	return { stars = stars, beams = beams, eyes = eyes }
end

function SkyBuilder.buildMoon(folder: Instance, center: Vector3, lookAt: Vector3): MoonParts
	local model = Parts.makeModel("Moon", folder)
	local face = CFrame.lookAt(center, lookAt)

	local body = Parts.makePart({
		name = "Body",
		size = Vector3.new(44, 44, 44),
		shape = Enum.PartType.Ball,
		cframe = face,
		color = Color3.fromRGB(236, 232, 206),
		material = Enum.Material.Neon,
		transparency = 0.25,
		canCollide = false,
		parent = model,
	})
	local glow = Parts.makePart({
		name = "Glow",
		size = Vector3.new(60, 60, 60),
		shape = Enum.PartType.Ball,
		cframe = face,
		color = Color3.fromRGB(240, 236, 214),
		material = Enum.Material.Neon,
		transparency = 0.9,
		canCollide = false,
		parent = model,
	})
	local eyes = {}
	for _, side in { -1, 1 } do
		local eye = Parts.makePart({
			name = "Eye",
			size = Vector3.new(4, 6, 4),
			shape = Enum.PartType.Ball,
			cframe = face * CFrame.new(side * 7, 5, -21),
			color = Color3.fromRGB(40, 40, 52),
			canCollide = false,
			parent = model,
		})
		table.insert(eyes, eye)
	end
	-- Foreshadowing: a brief red glint in one eye when the Moon gives a tip.
	local glint = Parts.makePart({
		name = "Glint",
		size = Vector3.new(2, 2, 2),
		shape = Enum.PartType.Ball,
		cframe = face * CFrame.new(7, 6, -23),
		color = Color3.fromRGB(255, 40, 40),
		material = Enum.Material.Neon,
		transparency = 1,
		canCollide = false,
		parent = model,
	})
	return { body = body, glow = glow, glintEye = glint }
end

return SkyBuilder
