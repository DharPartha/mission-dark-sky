--!strict
-- SelfTests: pure-logic checks for scoring, safety rules, and config validation.
-- Runs in Studio at server start (FeatureFlags.RunSelfTestsOnStart) and from the
-- command line with `python3 scripts/run_self_tests.py`. Cases are listed in tests/README.md.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")

local ExperienceConfig = require(ConfigFolder:WaitForChild("ExperienceConfig"))
local UIText = require(ConfigFolder:WaitForChild("UIText"))
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local MoonTipsConfig = require(ConfigFolder:WaitForChild("MoonTipsConfig"))
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local BossConfig = require(ConfigFolder:WaitForChild("BossConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local FixtureRules = require(SharedFolder:WaitForChild("FixtureRules"))
local ConfigValidator = require(SharedFolder:WaitForChild("ConfigValidator"))

local SelfTests = {}

local function deepCopy(value: any): any
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function realConfigs(): ConfigValidator.Configs
	return {
		ExperienceConfig = ExperienceConfig,
		UIText = UIText,
		DialogueConfig = DialogueConfig,
		MoonTipsConfig = MoonTipsConfig,
		FixtureConfig = FixtureConfig,
		BossConfig = BossConfig,
		Tuning = Tuning,
	}
end

local function reportMentions(report: ConfigValidator.Report, fragment: string): boolean
	for _, message in report.errors do
		if string.find(message, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function leoStates(): { [string]: any }
	local states = {}
	for _, def in FixtureConfig.Zones.Leo.fixtures do
		states[def.id] = FixtureRules.copyState(def.initial)
	end
	return states
end

local function findDef(id: string): any
	for _, def in FixtureConfig.Zones.Leo.fixtures do
		if def.id == id then
			return def
		end
	end
	error("No fixture " .. id)
end

-- Applies verb/option repeatedly until refused or limit reached.
local function applyUntilRefused(def: any, state: any, verb: string, option: string): any
	for _ = 1, 20 do
		local result = FixtureRules.apply(def, state, verb, option)
		if not result.ok then
			return state
		end
		state = result.state
	end
	return state
end

-- The "good answer" for a fixture: shield, aim down, dim to recommended, warm to 3000K.
local function responsiblyFix(def: any, state: any): any
	state = FixtureRules.apply(def, state, "SHIELD", "toggle").state
	state = applyUntilRefused(def, state, "AIM", "down")
	while state.brightness > def.recommendedBrightness + 1e-6 do
		state = FixtureRules.apply(def, state, "DIM", "down").state
	end
	while state.colorTempK > 3000 do
		state = FixtureRules.apply(def, state, "WARM", "warmer").state
	end
	return state
end

local cases: { { name: string, run: () -> () } } = {
	{
		name = "Shipped config passes the validator",
		run = function()
			local report = ConfigValidator.validate(realConfigs())
			assert(#report.errors == 0, "Validator errors: " .. table.concat(report.errors, " | "))
		end,
	},
	{
		name = "Validator catches overlong dialogue",
		run = function()
			local configs = deepCopy(realConfigs())
			configs.DialogueConfig.Lines.intro_1.text.en = string.rep("a", 91)
			assert(reportMentions(ConfigValidator.validate(configs), "intro_1"), "overlong line not caught")
		end,
	},
	{
		name = "Validator catches missing translations",
		run = function()
			local configs = deepCopy(realConfigs())
			configs.ExperienceConfig.SupportedLocales = { "en", "es" }
			assert(reportMentions(ConfigValidator.validate(configs), "missing 'es' text"), "missing es not caught")
		end,
	},
	{
		name = "Validator catches broken trigger and missing evidence",
		run = function()
			local configs = deepCopy(realConfigs())
			configs.MoonTipsConfig.Tips[1].trigger = "whenever"
			configs.MoonTipsConfig.Tips[1].evidenceKey = "nope"
			local report = ConfigValidator.validate(configs)
			assert(reportMentions(report, "trigger"), "bad trigger not caught")
			assert(reportMentions(report, "evidenceKey 'nope'"), "missing evidence not caught")
		end,
	},
	{
		name = "Validator rejects timers on safety-critical lights",
		run = function()
			local configs = deepCopy(realConfigs())
			for _, def in configs.FixtureConfig.Zones.Leo.fixtures do
				if def.need == "Required" then
					def.allowedSchedules = { "AllNight", "Motion" }
				end
			end
			assert(reportMentions(ConfigValidator.validate(configs), "safety-critical"), "unsafe schedule not caught")
		end,
	},
	{
		name = "Asset id format check",
		run = function()
			assert(ConfigValidator.isValidAssetId(""), "empty id should be allowed (placeholder)")
			assert(ConfigValidator.isValidAssetId("rbxassetid://12345"), "valid id rejected")
			assert(not ConfigValidator.isValidAssetId("12345abc"), "invalid id accepted")
			assert(not ConfigValidator.isValidAssetId(42), "non-string id accepted")
		end,
	},
	{
		name = "Leo starts polluted, with safe paths lit",
		run = function()
			local summary = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, leoStates())
			assert(summary.safePathLit, "starting paths should be lit")
			assert(summary.score < 40, "starting score should be low, got " .. summary.score)
			assert(not DarknessMath.isRestored(FixtureConfig.Zones.Leo, summary), "should not start restored")
		end,
	},
	{
		name = "Responsible fixes restore Leo",
		run = function()
			local states = leoStates()
			for _, def in FixtureConfig.Zones.Leo.fixtures do
				states[def.id] = responsiblyFix(def, states[def.id])
			end
			local summary = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, states)
			assert(summary.safePathLit, "fixed zone must keep safe paths lit")
			assert(DarknessMath.isRestored(FixtureConfig.Zones.Leo, summary), "fixed zone should restore, got " .. summary.score)
		end,
	},
	{
		name = "Shielding one light alone is not enough",
		run = function()
			local states = leoStates()
			local def = findDef("leo_lamp_corner")
			states[def.id] = FixtureRules.apply(def, states[def.id], "SHIELD", "toggle").state
			local summary = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, states)
			assert(not DarknessMath.isRestored(FixtureConfig.Zones.Leo, summary), "one shield should not restore")
		end,
	},
	{
		name = "Safety-critical light cannot be switched off",
		run = function()
			local def = findDef("leo_crossing")
			local result = FixtureRules.apply(def, def.initial, "QUESTION", "off")
			assert(not result.ok and result.state.on, "crossing light switched off")
			assert(result.noticeKey == "notice_off_refused_required", "wrong refusal notice")
			assert(result.evidenceKey == "crossing_needed", "refusal should still give evidence")
		end,
	},
	{
		name = "Useful lights cannot be switched off either",
		run = function()
			local def = findDef("leo_lamp_corner")
			local result = FixtureRules.apply(def, def.initial, "QUESTION", "off")
			assert(not result.ok and result.state.on, "useful light switched off")
		end,
	},
	{
		name = "DIM stops at the safety floor",
		run = function()
			local def = findDef("leo_crossing")
			local state = applyUntilRefused(def, FixtureRules.copyState(def.initial), "DIM", "down")
			assert(math.abs(state.brightness - def.minBrightness) < 1e-6, "floor not respected: " .. state.brightness)
			local refused = FixtureRules.apply(def, state, "DIM", "down")
			assert(not refused.ok and refused.noticeKey == "notice_dim_floor_safety", "floor refusal missing")
		end,
	},
	{
		name = "Safety light timer stays all night",
		run = function()
			local def = findDef("leo_crossing")
			local result = FixtureRules.apply(def, def.initial, "TIME", "next")
			assert(not result.ok and result.state.schedule == "AllNight", "safety timer changed")
		end,
	},
	{
		name = "Shield and aim shrink glare and sky glow",
		run = function()
			local def = findDef("leo_flood_garage")
			local before = DarknessMath.readFixture(def, def.initial)
			local zoneBefore = DarknessMath.glareZone(def, def.initial)
			local fixed = responsiblyFix(def, FixtureRules.copyState(def.initial))
			local after = DarknessMath.readFixture(def, fixed)
			assert(after.glare < before.glare, "glare did not drop")
			assert(after.uplight < before.uplight, "sky glow did not drop")
			assert(zoneBefore ~= nil, "polluted flood should have a glare zone")
			assert(DarknessMath.glareZone(def, fixed) == nil, "fixed flood should have no glare zone")
		end,
	},
	{
		name = "Unknown verbs and options are refused",
		run = function()
			local def = findDef("leo_lamp_corner")
			assert(not FixtureRules.apply(def, def.initial, "EXPLODE", "now").ok, "unknown verb accepted")
			assert(not FixtureRules.apply(def, def.initial, "DIM", "sideways").ok, "unknown option accepted")
		end,
	},
	{
		name = "Same inputs give the same score",
		run = function()
			local a = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, leoStates())
			local b = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, leoStates())
			assert(a.score == b.score and a.glare == b.glare, "scoring is not deterministic")
		end,
	},
}

-- Returns the number passed and a list of failure messages. Never throws.
function SelfTests.run(): (number, { string })
	local passed = 0
	local failures: { string } = {}
	for _, case in cases do
		local ok, message = pcall(case.run)
		if ok then
			passed += 1
		else
			table.insert(failures, case.name .. ": " .. tostring(message))
		end
	end
	return passed, failures
end

-- Readable score numbers for the balance table in docs (not assertions).
function SelfTests.scoreReport(): { [string]: number }
	local zone = FixtureConfig.Zones.Leo
	local report = {}
	report.start = DarknessMath.summarizeZone(zone, leoStates()).score
	local states = leoStates()
	for _, def in zone.fixtures do
		states[def.id] = FixtureRules.apply(def, states[def.id], "SHIELD", "toggle").state
	end
	report.allShielded = DarknessMath.summarizeZone(zone, states).score
	states = leoStates()
	for _, def in zone.fixtures do
		states[def.id] = responsiblyFix(def, states[def.id])
	end
	report.allFixed = DarknessMath.summarizeZone(zone, states).score
	return report
end

return SelfTests
