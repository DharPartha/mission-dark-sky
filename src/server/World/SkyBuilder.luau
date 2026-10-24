--!strict
-- SkyBuilder: the guardians' constellation creatures (star points + beams + glaring eyes) and the
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

-- Builds a guardian's constellation on its sky panel, facing the arena where players stand.
function SkyBuilder.buildConstellation(bossId: string, folder: Instance): LeoParts
	local boss = (BossConfig :: any)[bossId]
	local model = Parts.makeModel(bossId, folder)
	local stars: { BasePart } = {}
	local beams: { Beam } = {}
	local attachments: { [string]: Attachment } = {}

	-- Center the figure on the panel: midpoint of its star grid.
	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	for _, point in boss.starPoints do
		minU, maxU = math.min(minU, point.u), math.max(maxU, point.u)
		minV, maxV = math.min(minV, point.v), math.max(maxV, point.v)
	end
	local midU, midV = (minU + maxU) / 2, (minV + maxV) / 2
	local center: Vector3 = boss.panelCenter
	local look = Vector3.new(center.X - boss.viewerPosition.X, 0, center.Z - boss.viewerPosition.Z).Unit
	local right = look:Cross(Vector3.yAxis)

	local function starPosition(u: number, v: number): Vector3
		-- u grows toward the viewer's left, so figures read like sky charts.
		return center + Vector3.yAxis * (v - midV) * boss.gridScale - right * (u - midU) * boss.gridScale
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

	-- Glaring eyes near the head star. They fade when the guardian is calmed.
	local eyes: { BasePart } = {}
	local headPoint = boss.starPoints[boss.eyeStar or ""] or { u = midU, v = maxV }
	local headPosition = starPosition(headPoint.u, headPoint.v) - look * 4 + Vector3.yAxis * 2
	for _, side in { -1, 1 } do
		local eye = Parts.makePart({
			name = "Eye",
			size = Vector3.new(3, 3, 3),
			shape = Enum.PartType.Ball,
			cframe = CFrame.new(headPosition + right * side * 3),
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
		-- Solid and bright so the Moon reads clearly in the night sky.
		color = Color3.fromRGB(246, 242, 220),
		material = Enum.Material.Neon,
		transparency = 0,
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
