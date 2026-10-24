--!strict
-- Sweep (Orion): a searchlight lane is marked across the arena; it fires after the
-- telegraph. Step out of the red lane. The lane narrows as the zone's lights are fixed.

local AttackFx = require(script.Parent:WaitForChild("AttackFx"))

local random = Random.new()

return function(context: AttackFx.Context)
	local boss = context.boss
	local attack = boss.attack
	local width = attack.minWidth + (attack.maxWidth - attack.minWidth) * context.intensity
	local angle = random:NextNumber(0, math.pi)
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	-- Aim the lane at a random player half the time, so standing still is not always safe.
	local center: Vector3 = boss.arenaCenter
	local targets = context.playersInArena()
	if #targets > 0 and random:NextNumber() < 0.5 then
		local rootPart = AttackFx.rootOf(targets[random:NextInteger(1, #targets)])
		if rootPart then
			center = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
		end
	end
	local lane = AttackFx.lane(center, direction, boss.arenaRadius * 2, width, context.folder)
	task.wait(context.telegraphSeconds)
	if context.isStale() then
		AttackFx.cleanup({ lane })
		return
	end
	for _, player in context.playersInArena() do
		local rootPart = AttackFx.rootOf(player)
		if rootPart then
			local offset = Vector3.new(rootPart.Position.X - center.X, 0, rootPart.Position.Z - center.Z)
			-- Distance from the lane's center line.
			local across = (offset - direction * offset:Dot(direction)).Magnitude
			if across <= width / 2 then
				context.glare(player)
			end
		end
	end
	AttackFx.finish({ lane })
end
