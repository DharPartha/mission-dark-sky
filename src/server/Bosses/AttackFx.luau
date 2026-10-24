--!strict
-- AttackFx: shared helpers for boss attacks. Telegraph shapes are flat, red, translucent
-- ground markers (readable from above and on phones). Each attack ends with ONE soft flash
-- (never more than one per attack, far below three flashes per second).

local AttackFx = {}

export type Context = {
	boss: { [string]: any },
	-- 0 (zone nearly fixed) to 1 (fully polluted): scales attack size.
	intensity: number,
	telegraphSeconds: number,
	-- Players inside the arena right now (re-read for hits).
	playersInArena: () -> { Player },
	-- Fixture glare zones of the boss's zone (roar).
	glareZones: () -> { { x: number, z: number, radius: number } },
	glare: (player: Player) -> (),
	-- True once the encounter stopped (realm restored or reset): attacks bail out.
	isStale: () -> boolean,
	folder: Instance,
}

local TELEGRAPH_COLOR = Color3.fromRGB(255, 70, 50)

function AttackFx.rootOf(player: Player): BasePart?
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return if rootPart and rootPart:IsA("BasePart") then rootPart else nil
end

function AttackFx.flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function marker(name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = TELEGRAPH_COLOR
	part.Transparency = 0.6
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Parent = parent
	return part
end

-- Flat disc on the ground (a cylinder's axis is X, so roll it 90 degrees).
function AttackFx.disc(center: Vector3, radius: number, parent: Instance): Part
	return marker("TelegraphDisc", Vector3.new(0.3, radius * 2, radius * 2), CFrame.new(center.X, 0.4, center.Z) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, parent)
end

function AttackFx.moveDisc(disc: BasePart, center: Vector3)
	disc.CFrame = CFrame.new(center.X, 0.4, center.Z) * CFrame.Angles(0, 0, math.rad(90))
end

-- Flat lane on the ground through `center` along `direction`.
function AttackFx.lane(center: Vector3, direction: Vector3, length: number, width: number, parent: Instance): Part
	local flat = Vector3.new(center.X, 0.4, center.Z)
	return marker("TelegraphLane", Vector3.new(width, 0.3, length), CFrame.lookAt(flat, flat + direction), Enum.PartType.Block, parent)
end

-- One soft flash, then the markers disappear.
function AttackFx.finish(markers: { BasePart })
	for _, part in markers do
		part.Transparency = 0.25
	end
	task.delay(0.35, function()
		for _, part in markers do
			part:Destroy()
		end
	end)
end

function AttackFx.cleanup(markers: { BasePart })
	for _, part in markers do
		part:Destroy()
	end
end

return AttackFx
