--!strict
-- PartyRules: how the game adapts to party size. Solo players are never at a disadvantage:
-- every required step is solvable alone; bigger teams get slightly faster boss cycles but
-- the same warning time, and votes get a little more time to gather everyone's choice.

local Tuning = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("Tuning"))

local PartyRules = {}

export type BossTiming = { interval: number, telegraph: number }

-- Boss attack cycle for the number of players in the server.
function PartyRules.bossTiming(baseInterval: number, baseTelegraph: number, partySize: number): BossTiming
	local bosses = Tuning.Bosses
	if partySize <= 1 then
		return {
			interval = baseInterval * bosses.SoloIntervalMultiplier,
			telegraph = baseTelegraph + bosses.SoloExtraTelegraphSeconds,
		}
	end
	-- Larger teams: up to 15% faster cycles (more people to share the work), never shorter warnings.
	local speedUp = math.min(partySize - 2, 2) * 0.075
	return {
		interval = math.max(baseInterval * (1 - speedUp), baseTelegraph + 2),
		telegraph = baseTelegraph,
	}
end

-- Seconds a Moon vote stays open: a little more time per extra player, capped.
function PartyRules.voteSeconds(baseSeconds: number, partySize: number): number
	return baseSeconds + math.clamp(partySize - 1, 0, 3) * 5
end

-- True when the team is big enough for co-op role tips.
function PartyRules.isTeam(partySize: number): boolean
	return partySize >= 2
end

return PartyRules
