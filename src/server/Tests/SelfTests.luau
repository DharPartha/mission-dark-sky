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
local MissionConfig = require(ConfigFolder:WaitForChild("MissionConfig"))
local AnalyticsConfig = require(ConfigFolder:WaitForChild("AnalyticsConfig"))
local ProfileSchema = require(SharedFolder:WaitForChild("ProfileSchema"))
local SessionLock = require(SharedFolder:WaitForChild("SessionLock"))
local RateLimiter = require(SharedFolder:WaitForChild("RateLimiter"))
local ProfileStore = require(script.Parent.Parent:WaitForChild("Persistence"):WaitForChild("ProfileStore"))

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
		MissionConfig = MissionConfig,
		AnalyticsConfig = AnalyticsConfig,
		WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig")),
		QuizConfig = require(ConfigFolder:WaitForChild("QuizConfig")),
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
			configs.DialogueConfig.Lines.opening_1.text.en = string.rep("a", 91)
			assert(reportMentions(ConfigValidator.validate(configs), "opening_1"), "overlong line not caught")
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

-- A store that behaves like a DataStore, with failures we can switch on.
local function fakeStore()
	local store = { data = {} :: { [string]: any }, failReads = 0, failBackup = false, writes = 0 }
	function store.UpdateAsync(self: any, key: string, transform: (any) -> any): any
		if self.failReads > 0 then
			self.failReads -= 1
			error("simulated DataStore outage")
		end
		-- Real DataStores hand the transform a copy, not the stored table.
		local current = self.data[key]
		local result = transform(if typeof(current) == "table" then deepCopy(current) else current)
		if result ~= nil then
			self.data[key] = deepCopy(result)
			self.writes += 1
		end
		return result
	end
	function store.SetAsync(self: any, key: string, value: any): any
		if self.failBackup then
			error("simulated backup failure")
		end
		self.data[key] = deepCopy(value)
		return nil
	end
	return store
end

local function newStore(store: any, jobId: string, clock: { now: number }): any
	return ProfileStore.new({
		store = store,
		jobId = jobId,
		now = function()
			return clock.now
		end,
		wait = function(seconds: number)
			clock.now += seconds
		end,
		staleLockSeconds = 300,
		maxAttempts = 4,
		baseBackoffSeconds = 1,
	})
end

local persistenceCases: { { name: string, run: () -> () } } = {
	{
		name = "Fresh player gets a new saved profile",
		run = function()
			local store = fakeStore()
			local result = newStore(store, "A", { now = 1000 }):load("player_1")
			assert(result.status == "new", "expected new, got " .. result.status)
			assert(store.data.player_1 and store.data.player_1.lock.jobId == "A", "lock not written")
		end,
	},
	{
		name = "Returning player keeps progress across servers",
		run = function()
			local store = fakeStore()
			local clock = { now = 1000 }
			local serverA = newStore(store, "A", clock)
			local first = serverA:load("player_1")
			first.profile.completedMissions.leo_slice = true
			first.profile.doubtTokens = 2
			assert(serverA:save("player_1", first.profile, true) == "saved", "save failed")
			local second = newStore(store, "B", clock):load("player_1")
			assert(second.status == "loaded", "expected loaded")
			assert(second.profile.completedMissions.leo_slice and second.profile.doubtTokens == 2, "progress lost")
		end,
	},
	{
		name = "Read failure never overwrites a real save",
		run = function()
			local store = fakeStore()
			local clock = { now = 1000 }
			local serverA = newStore(store, "A", clock)
			local first = serverA:load("player_1")
			first.profile.doubtTokens = 5
			serverA:save("player_1", first.profile, true)
			local writesBefore = store.writes
			store.failReads = 99
			local result = newStore(store, "B", clock):load("player_1")
			assert(result.status == "unsaved", "expected unsaved on outage")
			assert(store.writes == writesBefore, "something was written during an outage")
			assert(store.data.player_1.profile.doubtTokens == 5, "real save changed")
		end,
	},
	{
		name = "Temporary outage recovers with retries",
		run = function()
			local store = fakeStore()
			store.failReads = 2
			local result = newStore(store, "A", { now = 1000 }):load("player_1")
			assert(result.status == "new", "should succeed on a later attempt, got " .. result.status)
		end,
	},
	{
		name = "Corrupt save is backed up, then replaced",
		run = function()
			local store = fakeStore()
			store.data.player_1 = "garbage"
			local result = newStore(store, "A", { now = 1000 }):load("player_1")
			assert(result.status == "new", "expected a fresh profile, got " .. result.status)
			local backedUp = false
			for key, value in store.data do
				if string.find(key, "player_1_backup_", 1, true) and value.raw == "garbage" then
					backedUp = true
				end
			end
			assert(backedUp, "corrupt data was not backed up")
		end,
	},
	{
		name = "Corrupt save is not replaced if the backup fails",
		run = function()
			local store = fakeStore()
			store.data.player_1 = 12345
			store.failBackup = true
			local result = newStore(store, "A", { now = 1000 }):load("player_1")
			assert(result.status == "unsaved", "expected unsaved")
			assert(store.data.player_1 == 12345, "corrupt data overwritten without a backup")
		end,
	},
	{
		name = "Save from a newer game version is left alone",
		run = function()
			local store = fakeStore()
			store.data.player_1 = SessionLock.wrap({ schemaVersion = 99 }, nil, 0)
			local result = newStore(store, "A", { now = 1000 }):load("player_1")
			assert(result.status == "unsaved", "expected unsaved")
			assert(store.data.player_1.profile.schemaVersion == 99, "newer save overwritten")
		end,
	},
	{
		name = "Live lock from another server blocks, stale lock is taken over",
		run = function()
			local store = fakeStore()
			local clock = { now = 1000 }
			newStore(store, "A", clock):load("player_1") -- A holds the lock, never releases
			local blocked = newStore(store, "B", clock):load("player_1")
			assert(blocked.status == "unsaved", "B must not take a live lock")
			clock.now += 1000
			local takeover = newStore(store, "C", clock):load("player_1")
			assert(takeover.status == "loaded", "stale lock should be taken over")
			assert(newStore(store, "A", clock):save("player_1", takeover.profile, false) == "lock_lost", "A must stop writing")
		end,
	},
	{
		name = "Unversioned data migrates and bad fields are repaired",
		run = function()
			local profile, repairs = ProfileSchema.migrate({
				completedMissions = { leo_slice = true, junk = "yes" },
				doubtTokens = -3,
				journal = { { id = "realm:Leo", kind = "realm", key = "Leo", at = 1 }, { id = "realm:Leo", kind = "realm", key = "Leo" }, "bad" },
			})
			assert(profile ~= nil, "migration failed")
			local migrated = profile :: ProfileSchema.Profile
			assert(migrated.schemaVersion == ProfileSchema.CurrentVersion, "version not upgraded")
			-- v1 -> v2 turns the original Leo slice into Act I + Leo, with the tools unlocked.
			assert(migrated.completedMissions.act1 and migrated.completedMissions.leo, "leo_slice not migrated")
			assert(migrated.completedMissions.leo_slice == nil and migrated.completedMissions.junk == nil, "bool map not cleaned")
			assert(migrated.unlocks.luxLens and migrated.unlocks.bike, "unlocks not granted")
			assert(migrated.doubtTokens == 0, "negative tokens kept")
			assert(#migrated.journal == 1, "duplicate or bad journal entries kept")
			assert(typeof(repairs) == "table" and #repairs > 0, "repairs not reported")
		end,
	},
	{
		name = "Journal entries are unique and capped",
		run = function()
			local profile = ProfileSchema.default()
			assert(ProfileSchema.addJournalEntry(profile, { id = "a", kind = "note", key = "a", at = 0 }), "first add failed")
			assert(not ProfileSchema.addJournalEntry(profile, { id = "a", kind = "note", key = "a", at = 0 }), "duplicate added")
			for index = 1, ProfileSchema.MaxJournalEntries + 5 do
				ProfileSchema.addJournalEntry(profile, { id = "n" .. index, kind = "note", key = "x", at = 0 })
			end
			assert(#profile.journal == ProfileSchema.MaxJournalEntries, "journal not capped")
		end,
	},
	{
		name = "Rate limiter allows a burst, then throttles, then refills",
		run = function()
			local limiter = RateLimiter.new(3, 1)
			assert(limiter:allow("p", 0) and limiter:allow("p", 0) and limiter:allow("p", 0), "burst refused")
			assert(not limiter:allow("p", 0), "over-limit request allowed")
			assert(limiter:allow("p", 1.1), "did not refill")
			assert(limiter:allow("q", 0), "players must have separate buckets")
		end,
	},
	{
		name = "Restored fixtures are responsible and keep safety lights on",
		run = function()
			for _, def in FixtureConfig.Zones.Leo.fixtures do
				local state = FixtureRules.responsibleState(def :: any)
				assert(state.on or def.need == "Unneeded", "needed light switched off")
				assert(state.brightness >= def.minBrightness, "below safety floor")
				assert(state.shielded and state.aim == "Down", "not shielded/aimed down")
			end
			local states = {}
			for _, def in FixtureConfig.Zones.Leo.fixtures do
				states[def.id] = FixtureRules.responsibleState(def :: any)
			end
			local summary = DarknessMath.summarizeZone(FixtureConfig.Zones.Leo, states)
			assert(DarknessMath.isRestored(FixtureConfig.Zones.Leo, summary), "restored preset does not restore the zone")
		end,
	},
	{
		name = "Validator catches broken mission steps",
		run = function()
			local configs = deepCopy(realConfigs())
			local function stepById(stepId: string): any
				for _, mission in configs.MissionConfig.Missions do
					for _, step in mission.steps do
						if step.id == stepId then
							return step
						end
					end
				end
				error("no step " .. stepId)
			end
			stepById("home_inspect").zoneId = "Nowhere"
			stepById("moontip").tipId = "nope"
			stepById("ride").targetId = "moon_base"
			stepById("tools").unlocks = { "jetpack" }
			stepById("precheck").quizId = "final_exam"
			stepById("bikes").companions = "mars"
			local report = ConfigValidator.validate(configs)
			assert(reportMentions(report, "Nowhere"), "bad zone not caught")
			assert(reportMentions(report, "tipId 'nope'"), "bad tip not caught")
			assert(reportMentions(report, "moon_base"), "bad reach target not caught")
			assert(reportMentions(report, "jetpack"), "bad unlock not caught")
			assert(reportMentions(report, "final_exam"), "bad quiz not caught")
			assert(reportMentions(report, "mars"), "bad companion station not caught")
		end,
	},
}
table.insert(persistenceCases, {
	name = "Version 1 saves keep missions and drop step-number checkpoints",
	run = function()
		local profile = ProfileSchema.migrate({
			schemaVersion = 1,
			completedMissions = {},
			checkpoints = { leo_slice = 4 },
			doubtTokens = 1,
		})
		assert(profile ~= nil, "v1 migration failed")
		local migrated = profile :: ProfileSchema.Profile
		assert(migrated.schemaVersion == 2 and next(migrated.checkpoints) == nil, "numeric checkpoints kept")
		assert(migrated.doubtTokens == 1 and next(migrated.unlocks) == nil, "fields lost or tools granted wrongly")
	end,
})
table.insert(persistenceCases, {
	name = "Validator catches a quiz with a bad answer key",
	run = function()
		local configs = deepCopy(realConfigs())
		configs.QuizConfig.QuestionSets.core[1].correct = 9
		assert(reportMentions(ConfigValidator.validate(configs), "correct must be a choice number"), "bad answer key not caught")
	end,
})
-- Every zone (tutorial and the four realms) must teach the same rule: responsible fixes
-- win, darkness alone does not, and safety lights can never be switched off.
for zoneId, zone in FixtureConfig.Zones do
	table.insert(persistenceCases, {
		name = "Zone " .. zoneId .. ": starts polluted, responsible fixes restore it, safety holds",
		run = function()
			local states = {}
			for _, def in zone.fixtures do
				states[def.id] = FixtureRules.copyState(def.initial)
			end
			local start = DarknessMath.summarizeZone(zone :: any, states)
			assert(start.safePathLit, zoneId .. " must start with safe paths lit")
			assert(not DarknessMath.isRestored(zone :: any, start), zoneId .. " must not start restored (" .. start.score .. ")")

			-- Switch off everything the rules allow, change nothing else: not enough.
			local offOnly = {}
			for _, def in zone.fixtures do
				local result = FixtureRules.apply(def :: any, def.initial :: any, "QUESTION", "off")
				offOnly[def.id] = result.state
				if def.need ~= "Unneeded" then
					assert(not result.ok and result.state.on, zoneId .. ": needed light " .. def.id .. " was switched off")
				end
			end
			local darkOnly = DarknessMath.summarizeZone(zone :: any, offOnly)
			assert(not DarknessMath.isRestored(zone :: any, darkOnly), zoneId .. ": switching lights off alone restored the zone")

			local fixed = {}
			for _, def in zone.fixtures do
				fixed[def.id] = FixtureRules.responsibleState(def :: any)
			end
			local done = DarknessMath.summarizeZone(zone :: any, fixed)
			assert(done.safePathLit and DarknessMath.isRestored(zone :: any, done), zoneId .. ": responsible fixes do not restore (" .. done.score .. ")")
		end,
	})
end

for _, case in persistenceCases do
	table.insert(cases, case)
end

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
