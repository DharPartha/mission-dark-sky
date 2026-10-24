--!strict
-- FinaleRules: pure rules for the Moon finale's light phases (QUESTION, SHIELD & AIM, DIM,
-- TIME). A phase is done when enough of its fixtures meet the goal. Doubt Tokens can lower
-- how many are needed, but never to zero and never below what keeps the lesson.
-- Safety still comes from FixtureRules: no goal can be met by switching off a needed light.

local Types = require(script.Parent:WaitForChild("Types"))

local FinaleRules = {}

export type Goal = "unneededOff" | "shieldAim" | "dim" | "time"

local EPSILON = 1e-6

function FinaleRules.meets(goal: string, def: Types.FixtureDefinition, state: Types.FixtureState): boolean
	if goal == "unneededOff" then
		-- Only lights nobody needs count; needed lights can never be switched off anyway.
		return def.need == "Unneeded" and not state.on
	elseif goal == "shieldAim" then
		return state.on and state.shielded and state.aim == "Down"
	elseif goal == "dim" then
		return state.on and state.brightness <= def.recommendedBrightness + EPSILON
	elseif goal == "time" then
		return state.on and state.schedule ~= "AllNight"
	end
	return false
end

-- Number of the phase's fixtures that meet the goal right now.
function FinaleRules.metCount(
	goal: string,
	fixtureIds: { string },
	defs: { [string]: Types.FixtureDefinition },
	states: { [string]: Types.FixtureState }
): number
	local count = 0
	for _, fixtureId in fixtureIds do
		local def, state = defs[fixtureId], states[fixtureId]
		if def and state and FinaleRules.meets(goal, def, state) then
			count += 1
		end
	end
	return count
end

-- How many fixtures the team must fix, after any Doubt Token discount (minimum 1).
function FinaleRules.required(base: number, teamTokens: number, discountAt: number?): number
	if discountAt ~= nil and teamTokens >= discountAt and base > 1 then
		return base - 1
	end
	return base
end

-- The state a fixture has after a phase is done (used to rebuild the world when a saved
-- game resumes mid-finale). Mirrors what players do with the verbs; never unsafe.
function FinaleRules.applyGoal(goal: string, def: Types.FixtureDefinition, state: Types.FixtureState): Types.FixtureState
	local nextState = table.clone(state)
	if goal == "unneededOff" and def.need == "Unneeded" then
		nextState.on = false
	elseif goal == "shieldAim" then
		nextState.shielded = true
		nextState.aim = "Down"
	elseif goal == "dim" then
		nextState.brightness = math.max(def.minBrightness, def.recommendedBrightness)
	elseif goal == "time" then
		for _, schedule in def.allowedSchedules do
			if schedule ~= "AllNight" then
				nextState.schedule = schedule :: any
				break
			end
		end
	end
	return nextState
end

return FinaleRules
