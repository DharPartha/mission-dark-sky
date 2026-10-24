--!strict
-- FixtureRules: pure rules for the five lighting verbs. The server calls this after its
-- network checks (distance, cooldown, quest phase); this module decides whether the change
-- is allowed and what the new fixture state is.
--
-- Safety rules live here so they can never be skipped:
--   * Required and Useful lights cannot be switched off (only Unneeded ones can).
--   * DIM cannot go below a fixture's minBrightness.
--   * TIME only offers the schedules listed for that fixture.

local Config = script.Parent.Parent:WaitForChild("Config")
local Tuning = require(Config:WaitForChild("Tuning"))
local Types = require(script.Parent:WaitForChild("Types"))

local FixtureRules = {}

-- Every option each verb accepts. The server rejects anything else before calling apply.
FixtureRules.VerbOptions = {
	QUESTION = { ask = true, off = true },
	SHIELD = { toggle = true },
	AIM = { down = true, up = true },
	DIM = { down = true, up = true },
	TIME = { next = true },
	WARM = { warmer = true, cooler = true },
} :: { [string]: { [string]: boolean } }

local EPSILON = 1e-6

function FixtureRules.copyState(state: Types.FixtureState): Types.FixtureState
	return {
		on = state.on,
		brightness = state.brightness,
		shielded = state.shielded,
		aim = state.aim,
		colorTempK = state.colorTempK,
		schedule = state.schedule,
	}
end

local function refuse(state: Types.FixtureState, noticeKey: string): Types.ActionResult
	return { ok = false, state = state, noticeKey = noticeKey }
end

local function indexOf(list: { any }, value: any): number?
	for index, item in list do
		if item == value then
			return index
		end
	end
	return nil
end

local function roundToStep(value: number): number
	-- Avoids 0.30000000000000004 style drift after repeated steps.
	return math.floor(value * 100 + 0.5) / 100
end

function FixtureRules.isVerbAllowed(def: Types.FixtureDefinition, verb: string): boolean
	return indexOf(def.allowedVerbs, verb) ~= nil
end

-- The state a fixture shows once its realm is restored (used when a saved game resumes
-- with a realm already fixed): shielded, aimed down, recommended brightness, warm color.
-- Unneeded lights are switched off; needed lights always stay on.
function FixtureRules.responsibleState(def: Types.FixtureDefinition): Types.FixtureState
	local warmest = 3000
	if indexOf(Tuning.Fixture.ColorTemps, warmest) == nil then
		warmest = Tuning.Fixture.ColorTemps[1]
	end
	return {
		on = def.need ~= "Unneeded",
		brightness = math.max(def.minBrightness, def.recommendedBrightness),
		shielded = true,
		aim = "Down",
		colorTempK = math.min(def.initial.colorTempK, warmest),
		schedule = def.initial.schedule,
	}
end

function FixtureRules.apply(
	def: Types.FixtureDefinition,
	state: Types.FixtureState,
	verb: string,
	option: string
): Types.ActionResult
	local options = FixtureRules.VerbOptions[verb]
	if options == nil or not options[option] then
		return refuse(state, "notice_bad_request")
	end
	if not FixtureRules.isVerbAllowed(def, verb) then
		return refuse(state, "notice_verb_unavailable")
	end

	local nextState = FixtureRules.copyState(state)
	local fixtureTuning = Tuning.Fixture

	if verb == "QUESTION" then
		if option == "ask" then
			return { ok = true, state = nextState, noticeKey = def.questionNoticeKey, evidenceKey = def.evidenceOnQuestion }
		end
		-- option == "off": the safety rule. Needed lights are improved, never removed.
		if def.need == "Required" then
			local result = refuse(state, "notice_off_refused_required")
			result.evidenceKey = def.evidenceOnQuestion
			return result
		elseif def.need == "Useful" then
			return refuse(state, "notice_off_refused_useful")
		end
		nextState.on = false
		return { ok = true, state = nextState, noticeKey = "notice_off_ok" }
	end

	if not state.on then
		-- An unneeded light that was switched off can be brought back with Undo only.
		return refuse(state, "notice_verb_unavailable")
	end

	if verb == "SHIELD" then
		nextState.shielded = not state.shielded
		return {
			ok = true,
			state = nextState,
			noticeKey = if nextState.shielded then "notice_shield_on" else "notice_shield_off",
			evidenceKey = if nextState.shielded then "shield_cuts_glare" else nil,
		}
	elseif verb == "AIM" then
		local order = fixtureTuning.AimOrder
		local index = indexOf(order, state.aim) or 1
		local nextIndex = if option == "down" then index - 1 else index + 1
		if nextIndex < 1 or nextIndex > #order then
			return refuse(state, "notice_aim_limit")
		end
		nextState.aim = order[nextIndex] :: any
		return { ok = true, state = nextState, noticeKey = "notice_aim", noticeArg = "aim_" .. nextState.aim }
	elseif verb == "DIM" then
		local step = fixtureTuning.BrightnessStep
		if option == "down" then
			local target = roundToStep(state.brightness - step)
			if target < def.minBrightness - EPSILON then
				return refuse(state, if def.need == "Required" then "notice_dim_floor_safety" else "notice_dim_floor")
			end
			nextState.brightness = target
		else
			if state.brightness >= 1 - EPSILON then
				return refuse(state, "notice_dim_max")
			end
			nextState.brightness = math.min(1, roundToStep(state.brightness + step))
		end
		return {
			ok = true,
			state = nextState,
			noticeKey = "notice_dim",
			noticeArg = math.floor(nextState.brightness * 100 + 0.5),
		}
	elseif verb == "TIME" then
		local schedules = def.allowedSchedules
		if #schedules <= 1 then
			return refuse(state, if def.need == "Required" then "notice_schedule_fixed" else "notice_schedule_single")
		end
		local index = indexOf(schedules, state.schedule) or 0
		nextState.schedule = schedules[(index % #schedules) + 1] :: any
		return {
			ok = true,
			state = nextState,
			noticeKey = "notice_time",
			noticeArg = "schedule_" .. nextState.schedule,
			evidenceKey = if nextState.schedule ~= "AllNight" then "timer_used" else nil,
		}
	elseif verb == "WARM" then
		local temps = fixtureTuning.ColorTemps
		local index = indexOf(temps, state.colorTempK)
		if index == nil then
			-- Unknown starting value: snap to the nearest listed temperature first.
			index = #temps
			for i, temp in temps do
				if temp >= state.colorTempK then
					index = i
					break
				end
			end
		end
		local nextIndex = if option == "warmer" then (index :: number) - 1 else (index :: number) + 1
		if nextIndex < 1 then
			return refuse(state, "notice_warm_limit")
		elseif nextIndex > #temps then
			return refuse(state, "notice_cool_limit")
		end
		nextState.colorTempK = temps[nextIndex]
		return { ok = true, state = nextState, noticeKey = "notice_warm", noticeArg = nextState.colorTempK }
	end

	return refuse(state, "notice_bad_request")
end

return FixtureRules
