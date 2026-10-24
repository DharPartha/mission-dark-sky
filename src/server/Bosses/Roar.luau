--!strict
-- Roar (Leo): after the telegraph, players standing inside a fixture's glare zone are
-- dazzled. Glare zones come straight from fixture state, so shielding and aiming lights
-- literally create the safe shadow lanes.

local AttackFx = require(script.Parent:WaitForChild("AttackFx"))

return function(context: AttackFx.Context)
	local markers: { BasePart } = {}
	for _, zone in context.glareZones() do
		table.insert(markers, AttackFx.disc(Vector3.new(zone.x, 0, zone.z), zone.radius, context.folder))
	end
	task.wait(context.telegraphSeconds)
	if context.isStale() then
		AttackFx.cleanup(markers)
		return
	end
	-- Hit test uses the zones as they are NOW: a light fixed during the telegraph helps.
	local zones = context.glareZones()
	for _, player in context.playersInArena() do
		local rootPart = AttackFx.rootOf(player)
		if rootPart then
			for _, zone in zones do
				if AttackFx.flatDistance(rootPart.Position, Vector3.new(zone.x, 0, zone.z)) <= zone.radius then
					context.glare(player)
					break
				end
			end
		end
	end
	AttackFx.finish(markers)
end
