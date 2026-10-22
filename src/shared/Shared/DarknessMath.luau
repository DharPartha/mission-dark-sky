--!strict
-- DarknessMath: pure scoring. Turns fixture states into Lux Lens readings and one
-- authoritative 0-100 Darkness score per zone (higher = healthier night).
--
-- Design choices:
--   * Each fixture gets a "harm" from four problems: glare, uplight (sky glow),
--     over-lighting, and blue-rich color. Timers scale harm by how long the light is on.
--   * Safety is a constraint, not a score: FixtureRules stops needed lights from being
--     switched off or dimmed below their floor, so darkness alone can never win.
--   * All numbers are game estimates for teaching, not real measurements.

local Config = script.Parent.Parent:WaitForChild("Config")
local Tuning = require(Config:WaitForChild("Tuning"))
local Types = require(script.Parent:WaitForChild("Types"))

local DarknessMath = {}

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

function DarknessMath.readFixture(def: Types.FixtureDefinition, state: Types.FixtureState): Types.FixtureReadings
	if not state.on then
		return { brightness = 0, glare = 0, uplight = 0, blueLight = 0, overLight = 0, harm = 0 }
	end

	local fixtureTuning = Tuning.Fixture
	local brightness = clamp01(state.brightness)
	local shieldFactor = if state.shielded then fixtureTuning.ShieldedGlareFactor else 1
	local aimGlare = (fixtureTuning.AimGlare :: any)[state.aim] or 1
	local aimUplight = (fixtureTuning.AimUplight :: any)[state.aim] or 0
	local sideways = if state.shielded then 0 else fixtureTuning.UnshieldedUplight

	local glare = clamp01(brightness * shieldFactor * aimGlare)
	-- A shield blocks sideways spill, but a fixture tilted upward still lights the sky.
	local uplight = clamp01(brightness * (sideways + aimUplight))
	local overRange = math.max(1 - def.recommendedBrightness, 0.01)
	local overLight = clamp01((brightness - def.recommendedBrightness) / overRange)
	local blueLight = clamp01(
		(state.colorTempK - fixtureTuning.WarmK) / (fixtureTuning.CoolK - fixtureTuning.WarmK)
	)

	local weights = Tuning.Score.Weights
	local weightSum = weights.glare + weights.uplight + weights.overLight + weights.blueLight
	local onFraction = (fixtureTuning.ScheduleOnFraction :: any)[state.schedule] or 1
	local harm = onFraction
		* (weights.glare * glare + weights.uplight * uplight + weights.overLight * overLight + weights.blueLight * blueLight)
		/ weightSum

	return {
		brightness = brightness,
		glare = glare,
		uplight = uplight,
		blueLight = blueLight,
		overLight = overLight,
		harm = clamp01(harm),
	}
end

-- Needed lights must be on and at or above their floor for the path to count as safe.
function DarknessMath.isSafelyLit(def: Types.FixtureDefinition, state: Types.FixtureState): boolean
	if def.need == "Unneeded" then
		return true
	end
	return state.on and state.brightness >= def.minBrightness - 1e-6
end

function DarknessMath.summarizeZone(
	zone: Types.ZoneDefinition,
	states: { [string]: Types.FixtureState }
): Types.ZoneSummary
	local weightTotal = 0
	local harmTotal, glareTotal, uplightTotal, blueTotal = 0, 0, 0, 0
	local safePathLit = true

	for _, def in zone.fixtures do
		local state = states[def.id] or def.initial
		local readings = DarknessMath.readFixture(def, state)
		weightTotal += def.weight
		harmTotal += readings.harm * def.weight
		glareTotal += readings.glare * def.weight
		uplightTotal += readings.uplight * def.weight
		blueTotal += readings.blueLight * def.weight
		if not DarknessMath.isSafelyLit(def, state) then
			safePathLit = false
		end
	end

	if weightTotal <= 0 then
		return { score = 100, glare = 0, uplight = 0, blueLight = 0, safePathLit = safePathLit }
	end

	local averageHarm = harmTotal / weightTotal
	local score = math.floor(100 * (1 - averageHarm * Tuning.Score.HarmScale) + 0.5)
	return {
		score = math.clamp(score, 0, 100),
		glare = glareTotal / weightTotal,
		uplight = uplightTotal / weightTotal,
		blueLight = blueTotal / weightTotal,
		safePathLit = safePathLit,
	}
end

function DarknessMath.isRestored(zone: Types.ZoneDefinition, summary: Types.ZoneSummary): boolean
	return summary.safePathLit and summary.score >= zone.restoreThreshold
end

-- UIText key for the meter band containing this score.
function DarknessMath.bandKey(score: number): string
	local key = Tuning.Score.Bands[1].textKey
	for _, band in Tuning.Score.Bands do
		if score >= band.min then
			key = band.textKey
		end
	end
	return key
end

-- Where Leo's roar can reach: a circle on the ground under the light's bright pool.
-- Returns nil when the fixture's glare is too low to matter.
function DarknessMath.glareZone(def: Types.FixtureDefinition, state: Types.FixtureState): Types.GlareZone?
	local readings = DarknessMath.readFixture(def, state)
	if readings.glare < Tuning.Glare.MinGlare then
		return nil
	end
	local facing = math.rad(def.facingDegrees)
	local offset = (Tuning.Fixture.AimPoolOffset :: any)[state.aim] or 0
	return {
		fixtureId = def.id,
		x = def.position.X + math.sin(facing) * offset,
		z = def.position.Z + math.cos(facing) * offset,
		radius = Tuning.Glare.MaxRadius * readings.glare,
		glare = readings.glare,
	}
end

-- Converts a 0-1 reading to a whole number out of 10 for display.
function DarknessMath.toTen(value: number): number
	return math.floor(clamp01(value) * 10 + 0.5)
end

return DarknessMath
