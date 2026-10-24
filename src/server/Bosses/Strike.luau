--!strict
-- Strike (Scorpius, Cetus): a red circle appears under each player in the arena and lands
-- after the telegraph. With tracking (Cetus, "the Stalker") the circle follows you for most
-- of the telegraph, then locks; keep moving and break away at the end.

local AttackFx = require(script.Parent:WaitForChild("AttackFx"))

local MAX_TARGETS = 4
local TRACK_FRACTION = 0.65
local TRACK_STEP = 0.1

return function(context: AttackFx.Context)
	local attack = context.boss.attack
	local radius = attack.minRadius + (attack.maxRadius - attack.minRadius) * context.intensity
	local strikes: { { player: Player, disc: BasePart, center: Vector3 } } = {}
	for index, player in context.playersInArena() do
		if index > MAX_TARGETS then
			break
		end
		local rootPart = AttackFx.rootOf(player)
		if rootPart then
			local center = rootPart.Position
			table.insert(strikes, { player = player, disc = AttackFx.disc(center, radius, context.folder), center = center })
		end
	end
	if #strikes == 0 then
		return
	end

	local tracked = if attack.tracking then context.telegraphSeconds * TRACK_FRACTION else 0
	local elapsed = 0
	while elapsed < tracked do
		task.wait(TRACK_STEP)
		elapsed += TRACK_STEP
		for _, strike in strikes do
			local rootPart = AttackFx.rootOf(strike.player)
			if rootPart then
				strike.center = rootPart.Position
				AttackFx.moveDisc(strike.disc, strike.center)
			end
		end
	end
	task.wait(context.telegraphSeconds - tracked)

	local markers = {}
	for _, strike in strikes do
		table.insert(markers, strike.disc)
	end
	if context.isStale() then
		AttackFx.cleanup(markers)
		return
	end
	-- Anyone standing in any landing circle is dazzled (not only the original target).
	for _, player in context.playersInArena() do
		local rootPart = AttackFx.rootOf(player)
		if rootPart then
			for _, strike in strikes do
				if AttackFx.flatDistance(rootPart.Position, strike.center) <= radius then
					context.glare(player)
					break
				end
			end
		end
	end
	AttackFx.finish(markers)
end
