--!strict
-- ConfigValidator: checks the config modules so a non-programmer's edit fails with a
-- readable message instead of a broken game. Pure: pass in config tables, get back
-- lists of errors (must fix) and warnings (should fix).
--
-- Checks: missing keys, overlong dialogue, unknown speakers/styles, broken references
-- (sequences, hints, evidence, triggers, fixtures), missing translations, mismatched
-- placeholders, unsafe fixture settings, and asset id format.

local ConfigValidator = {}

ConfigValidator.MaxDialogueCharacters = 90

local VALID_STYLES = { speech = true, shout = true, thought = true, narration = true }
local VALID_NEEDS = { Required = true, Useful = true, Unneeded = true }
local VALID_VERBS = { QUESTION = true, SHIELD = true, AIM = true, DIM = true, TIME = true, WARM = true }
local VALID_SCHEDULES = { AllNight = true, Motion = true, Curfew = true }
local VALID_AIMS = { Down = true, Angled = true, Out = true, Up = true }
local QUEST_PHASES = {
	Intro = true,
	Quiz = true,
	Telescope = true,
	Investigate = true,
	HomeFix = true,
	Confront = true,
	Ride = true,
	Rift = true,
	Travel = true,
	Finale = true,
	OrionFix = true,
	ScorpiusFix = true,
	CetusFix = true,
	after = true,
}
-- Items a "grant" mission step may unlock.
ConfigValidator.KnownUnlocks = { luxLens = true, journal = true, bike = true }
-- Evidence the game itself records (see FixtureRules and FixturePuzzleService).
local BUILT_IN_EVIDENCE = {
	glare_reading = true,
	shield_cuts_glare = true,
	timer_used = true,
	skyglow_seen = true,
	echo_seen = true,
}
local PHASE_GOALS = { unneededOff = true, shieldAim = true, dim = true, time = true }

export type Configs = {
	ExperienceConfig: any,
	UIText: any,
	MissionConfig: any,
	AnalyticsConfig: any,
	WorldConfig: any,
	QuizConfig: any,
	PledgeConfig: any,
	ReportConfig: any,
	DialogueConfig: any,
	MoonTipsConfig: any,
	FixtureConfig: any,
	BossConfig: any,
	Tuning: any,
}

export type Report = { errors: { string }, warnings: { string } }

-- Accepts "" (no asset yet) or "rbxassetid://<digits>".
function ConfigValidator.isValidAssetId(value: any): boolean
	if typeof(value) ~= "string" then
		return false
	end
	return value == "" or string.match(value, "^rbxassetid://%d+$") ~= nil
end

local function placeholders(text: string): string
	local found = {}
	for token in string.gmatch(text, "%%[%d%.]*[dsf]") do
		table.insert(found, token)
	end
	return table.concat(found, ",")
end

function ConfigValidator.validate(configs: Configs): Report
	local errors: { string } = {}
	local warnings: { string } = {}
	local function fail(message: string, ...: any)
		table.insert(errors, string.format(message, ...))
	end
	local function warn(message: string, ...: any)
		table.insert(warnings, string.format(message, ...))
	end

	local experience = configs.ExperienceConfig
	local locales: { string } = experience.SupportedLocales or {}
	if typeof(experience.Title) ~= "string" or experience.Title == "" then
		fail("ExperienceConfig.Title is missing")
	end
	if table.find(locales, experience.DefaultLocale) == nil then
		fail("ExperienceConfig.DefaultLocale '%s' is not in SupportedLocales", tostring(experience.DefaultLocale))
	end

	-- Every localized table needs each supported locale, with matching placeholders.
	local function checkLocalized(where: string, localized: any, maxLength: number?)
		if typeof(localized) ~= "table" then
			fail("%s has no text table", where)
			return
		end
		local default = localized[experience.DefaultLocale]
		for _, locale in locales do
			local text = localized[locale]
			if typeof(text) ~= "string" or text == "" then
				fail("%s is missing '%s' text", where, locale)
			else
				if maxLength and utf8.len(text) and (utf8.len(text) :: number) > maxLength then
					fail("%s (%s) is %d characters; the limit is %d", where, locale, utf8.len(text) :: number, maxLength)
				end
				if typeof(default) == "string" and placeholders(text) ~= placeholders(default) then
					fail("%s (%s) has different %% placeholders than '%s'", where, locale, experience.DefaultLocale)
				end
			end
		end
	end

	local strings = configs.UIText.Strings or {}
	for key, localized in strings do
		checkLocalized("UIText." .. key, localized, nil)
	end
	local function needUIText(where: string, key: any)
		if typeof(key) ~= "string" or strings[key] == nil then
			fail("%s refers to UIText key '%s', which does not exist", where, tostring(key))
		end
	end

	-- Dialogue
	local dialogue = configs.DialogueConfig
	local lines = dialogue.Lines or {}
	for lineId, line in lines do
		local where = "DialogueConfig.Lines." .. lineId
		if dialogue.Speakers[line.speaker] == nil then
			fail("%s has unknown speaker '%s'", where, tostring(line.speaker))
		end
		if not VALID_STYLES[line.style] then
			fail("%s has unknown style '%s'", where, tostring(line.style))
		end
		checkLocalized(where, line.text, ConfigValidator.MaxDialogueCharacters)
	end
	local sequences = dialogue.Sequences or {}
	for sequenceId, list in sequences do
		if #list == 0 then
			fail("DialogueConfig.Sequences.%s is empty", sequenceId)
		end
		for _, lineId in list do
			if lines[lineId] == nil then
				fail("DialogueConfig.Sequences.%s refers to missing line '%s'", sequenceId, tostring(lineId))
			end
		end
	end
	local function needSequence(where: string, sequenceId: any)
		if typeof(sequenceId) ~= "string" or sequences[sequenceId] == nil then
			fail("%s refers to missing dialogue sequence '%s'", where, tostring(sequenceId))
		end
	end
	for friend, hints in dialogue.Hints or {} do
		if dialogue.Speakers[friend] == nil then
			fail("DialogueConfig.Hints.%s is not a speaker", friend)
		end
		if hints.after == nil then
			fail("DialogueConfig.Hints.%s needs an 'after' hint", friend)
		end
		for phase, lineId in hints do
			if not QUEST_PHASES[phase] then
				warn("DialogueConfig.Hints.%s.%s is not a phase that uses hints", friend, phase)
			end
			if lines[lineId] == nil then
				fail("DialogueConfig.Hints.%s.%s refers to missing line '%s'", friend, phase, tostring(lineId))
			end
		end
	end

	-- Evidence
	local tips = configs.MoonTipsConfig
	local evidence = tips.Evidence or {}
	for key, card in evidence do
		checkLocalized("MoonTipsConfig.Evidence." .. key .. ".title", card.title, nil)
		checkLocalized("MoonTipsConfig.Evidence." .. key .. ".text", card.text, nil)
	end
	local producedEvidence: { [string]: boolean } = table.clone(BUILT_IN_EVIDENCE)

	-- Fixtures and zones
	local tuning = configs.Tuning
	local zones = configs.FixtureConfig.Zones or {}
	local fixtureIds: { [string]: boolean } = {}
	for zoneId, zone in zones do
		local zoneWhere = "FixtureConfig.Zones." .. zoneId
		if zone.id ~= zoneId then
			fail("%s.id must be '%s'", zoneWhere, zoneId)
		end
		needUIText(zoneWhere .. ".nameKey", zone.nameKey)
		if typeof(zone.restoreThreshold) ~= "number" or zone.restoreThreshold <= 0 or zone.restoreThreshold > 100 then
			fail("%s.restoreThreshold must be between 1 and 100", zoneWhere)
		end
		if typeof(zone.fixtures) ~= "table" or #zone.fixtures == 0 then
			fail("%s has no fixtures", zoneWhere)
			continue
		end
		for index, def in zone.fixtures do
			local where = string.format("%s fixture #%d (%s)", zoneWhere, index, tostring(def.id))
			if typeof(def.id) ~= "string" or def.id == "" then
				fail("%s is missing an id", where)
			elseif fixtureIds[def.id] then
				fail("%s: id '%s' is used twice", where, def.id)
			else
				fixtureIds[def.id] = true
			end
			needUIText(where .. ".nameKey", def.nameKey)
			needUIText(where .. ".questionNoticeKey", def.questionNoticeKey)
			if not VALID_NEEDS[def.need] then
				fail("%s.need '%s' must be Required, Useful, or Unneeded", where, tostring(def.need))
			end
			for _, verb in def.allowedVerbs or {} do
				if not VALID_VERBS[verb] then
					fail("%s has unknown verb '%s'", where, tostring(verb))
				end
			end
			for _, schedule in def.allowedSchedules or {} do
				if not VALID_SCHEDULES[schedule] then
					fail("%s has unknown schedule '%s'", where, tostring(schedule))
				end
			end
			if def.need == "Required" and (#def.allowedSchedules ~= 1 or def.allowedSchedules[1] ~= "AllNight") then
				fail("%s is Required (safety-critical), so allowedSchedules must be { \"AllNight\" }", where)
			end
			if typeof(def.minBrightness) ~= "number" or typeof(def.recommendedBrightness) ~= "number" then
				fail("%s needs minBrightness and recommendedBrightness numbers", where)
			elseif not (def.minBrightness >= 0 and def.minBrightness <= def.recommendedBrightness and def.recommendedBrightness <= 1) then
				fail("%s must satisfy 0 <= minBrightness <= recommendedBrightness <= 1", where)
			elseif def.need ~= "Unneeded" and def.minBrightness <= 0 then
				fail("%s is needed, so minBrightness must be above 0", where)
			end
			if typeof(def.weight) ~= "number" or def.weight <= 0 then
				fail("%s.weight must be a positive number", where)
			end
			local initial = def.initial
			if typeof(initial) ~= "table" then
				fail("%s has no initial state", where)
			else
				if def.need ~= "Unneeded" and initial.on ~= true then
					fail("%s is needed, so it must start switched on", where)
				end
				if typeof(initial.brightness) ~= "number" or initial.brightness < def.minBrightness or initial.brightness > 1 then
					fail("%s initial brightness must be between minBrightness and 1", where)
				end
				if not VALID_AIMS[initial.aim] then
					fail("%s initial aim '%s' is not valid", where, tostring(initial.aim))
				end
				if table.find(tuning.Fixture.ColorTemps, initial.colorTempK) == nil then
					fail("%s initial colorTempK %s is not in Tuning.Fixture.ColorTemps", where, tostring(initial.colorTempK))
				end
				if table.find(def.allowedSchedules or {}, initial.schedule) == nil then
					fail("%s initial schedule '%s' is not in allowedSchedules", where, tostring(initial.schedule))
				end
			end
			if def.evidenceOnQuestion ~= nil then
				if evidence[def.evidenceOnQuestion] == nil then
					fail("%s.evidenceOnQuestion '%s' is not in MoonTipsConfig.Evidence", where, tostring(def.evidenceOnQuestion))
				else
					producedEvidence[def.evidenceOnQuestion] = true
				end
			end
		end
	end

	-- Town echoes: decorative lights tied to a zone.
	for zoneId, echoes in configs.FixtureConfig.Echoes or {} do
		if zones[zoneId] == nil then
			fail("FixtureConfig.Echoes.%s is not a zone", zoneId)
		end
		for index, def in echoes do
			local where = string.format("FixtureConfig.Echoes.%s[%d]", zoneId, index)
			if typeof(def.id) ~= "string" or fixtureIds[def.id] then
				fail("%s needs a unique id", where)
			else
				fixtureIds[def.id] = true
			end
			if typeof(def.initial) ~= "table" or typeof(def.minBrightness) ~= "number" then
				fail("%s needs initial state and brightness numbers", where)
			end
		end
	end

	-- Meter bands
	local previousMin = -1
	for index, band in tuning.Score.Bands do
		needUIText(string.format("Tuning.Score.Bands[%d]", index), band.textKey)
		if band.min <= previousMin then
			fail("Tuning.Score.Bands must be in increasing order of min")
		end
		previousMin = band.min
	end
	for temp in tuning.Fixture.ColorTempRGB do
		if table.find(tuning.Fixture.ColorTemps, temp) == nil then
			warn("Tuning.Fixture.ColorTempRGB has %dK, which is not in ColorTemps", temp)
		end
	end
	for _, temp in tuning.Fixture.ColorTemps do
		if tuning.Fixture.ColorTempRGB[temp] == nil then
			fail("Tuning.Fixture.ColorTempRGB is missing a color for %dK", temp)
		end
	end

	-- Bosses
	for bossId, boss in configs.BossConfig do
		local where = "BossConfig." .. bossId
		needUIText(where .. ".nameKey", boss.nameKey)
		if zones[boss.zoneId] == nil then
			fail("%s.zoneId '%s' is not a zone in FixtureConfig", where, tostring(boss.zoneId))
		end
		for _, pair in boss.lines or {} do
			for _, starName in pair do
				if boss.starPoints[starName] == nil then
					fail("%s.lines uses unknown star '%s'", where, tostring(starName))
				end
			end
		end
		needSequence(where .. ".wakeSequence", boss.wakeSequence)
		needSequence(where .. ".restoredSequence", boss.restoredSequence)
		needUIText(where .. ".telegraphKey", boss.telegraphKey)
		if boss.eyeStar ~= nil and boss.starPoints[boss.eyeStar] == nil then
			fail("%s.eyeStar '%s' is not one of its stars", where, tostring(boss.eyeStar))
		end
		local attack = boss.attack
		if typeof(attack) ~= "table" or (attack.kind ~= "roar" and attack.kind ~= "sweep" and attack.kind ~= "strike") then
			fail("%s.attack.kind must be roar, sweep, or strike", where)
		elseif typeof(attack.telegraphSeconds) ~= "number" or typeof(attack.intervalSeconds) ~= "number"
			or attack.telegraphSeconds >= attack.intervalSeconds
		then
			fail("%s.attack.telegraphSeconds must be shorter than intervalSeconds", where)
		elseif attack.telegraphSeconds < 1.5 then
			-- Telegraphs must stay readable.
			fail("%s.attack.telegraphSeconds must be at least 1.5 seconds", where)
		end
		if typeof(boss.arenaRadius) ~= "number" or boss.arenaRadius <= 0 then
			fail("%s.arenaRadius must be a positive number", where)
		end
	end

	-- Moon tips
	local tipIds: { [string]: boolean } = {}
	for index, tip in tips.Tips or {} do
		local where = string.format("MoonTipsConfig.Tips[%d] (%s)", index, tostring(tip.id))
		if typeof(tip.id) ~= "string" or tipIds[tip.id] then
			fail("%s needs a unique id", where)
		else
			tipIds[tip.id] = true
		end
		if lines[tip.lineId] == nil then
			fail("%s.lineId '%s' is not a dialogue line", where, tostring(tip.lineId))
		end
		if typeof(tip.isMisleading) ~= "boolean" then
			fail("%s.isMisleading must be true or false", where)
		end
		if evidence[tip.evidenceKey] == nil then
			fail("%s.evidenceKey '%s' is not in Evidence", where, tostring(tip.evidenceKey))
		elseif not producedEvidence[tip.evidenceKey] then
			fail("%s.evidenceKey '%s' can never be found in the world before the tip", where, tip.evidenceKey)
		end
		local trigger = tip.trigger
		local triggerZone = if typeof(trigger) == "string" then string.match(trigger, "^afterRealm:(%w+)$") else nil
		if trigger ~= "rift" and trigger ~= "finale" and triggerZone == nil then
			fail("%s.trigger '%s' must be 'rift', 'finale', or 'afterRealm:<ZoneId>'", where, tostring(trigger))
		elseif triggerZone and zones[triggerZone] == nil then
			fail("%s.trigger names unknown zone '%s'", where, triggerZone)
		end
		needSequence(where .. ".onDoubt", tip.onDoubt)
		needSequence(where .. ".onAgree", tip.onAgree)
		needSequence(where .. ".onTie", tip.onTie)
	end

	-- Missions
	local missionIds: { [string]: boolean } = {}
	local tipIdSet: { [string]: boolean } = {}
	for _, tip in tips.Tips or {} do
		tipIdSet[tip.id] = true
	end
	local validKinds = {
		dialogue = true,
		quiz = true,
		interact = true,
		grant = true,
		inspect = true,
		restore = true,
		reach = true,
		moonTip = true,
		phase = true,
		claims = true,
		ending = true,
		pledge = true,
	}
	local world = configs.WorldConfig
	local quizzes = configs.QuizConfig
	for index, mission in configs.MissionConfig.Missions or {} do
		local where = string.format("MissionConfig.Missions[%d] (%s)", index, tostring(mission.id))
		if typeof(mission.id) ~= "string" or missionIds[mission.id] then
			fail("%s needs a unique id", where)
		else
			missionIds[mission.id] = true
		end
		needUIText(where .. ".titleKey", mission.titleKey)
		for _, zoneId in mission.zonesRestored or {} do
			if zones[zoneId] == nil then
				fail("%s.zonesRestored names unknown zone '%s'", where, tostring(zoneId))
			end
		end
		if typeof(mission.steps) ~= "table" or #mission.steps == 0 then
			fail("%s has no steps", where)
			continue
		end
		local stepIds: { [string]: boolean } = {}
		for stepIndex, step in mission.steps do
			local stepWhere = string.format("%s step %d (%s)", where, stepIndex, tostring(step.id))
			if typeof(step.id) ~= "string" or stepIds[step.id] then
				fail("%s needs a unique id", stepWhere)
			else
				stepIds[step.id] = true
			end
			needUIText(stepWhere .. ".objectiveKey", step.objectiveKey)
			if not validKinds[step.kind] then
				fail("%s has unknown kind '%s'", stepWhere, tostring(step.kind))
			elseif step.kind == "dialogue" then
				needSequence(stepWhere .. ".sequence", step.sequence)
			elseif step.kind == "inspect" or step.kind == "restore" then
				if zones[step.zoneId] == nil then
					fail("%s.zoneId '%s' is not a zone", stepWhere, tostring(step.zoneId))
				end
				if step.kind == "restore" then
					if step.bossId ~= nil and configs.BossConfig[step.bossId] == nil then
						fail("%s.bossId '%s' is not in BossConfig", stepWhere, tostring(step.bossId))
					end
					if step.enterSequence ~= nil then
						needSequence(stepWhere .. ".enterSequence", step.enterSequence)
					end
				end
			elseif step.kind == "moonTip" and not tipIdSet[step.tipId] then
				fail("%s.tipId '%s' is not in MoonTipsConfig", stepWhere, tostring(step.tipId))
			elseif step.kind == "quiz" and quizzes.Quizzes[step.quizId] == nil then
				fail("%s.quizId '%s' is not in QuizConfig", stepWhere, tostring(step.quizId))
			elseif step.kind == "interact" and world.Interactables[step.targetId] == nil then
				fail("%s.targetId '%s' is not in WorldConfig.Interactables", stepWhere, tostring(step.targetId))
			elseif step.kind == "reach" and world.Triggers[step.targetId] == nil then
				fail("%s.targetId '%s' is not in WorldConfig.Triggers", stepWhere, tostring(step.targetId))
			elseif step.kind == "grant" then
				if typeof(step.unlocks) ~= "table" or #step.unlocks == 0 then
					fail("%s needs an unlocks list", stepWhere)
				else
					for _, unlock in step.unlocks do
						if not ConfigValidator.KnownUnlocks[unlock] then
							fail("%s unlocks unknown item '%s'", stepWhere, tostring(unlock))
						end
						needUIText(stepWhere .. " unlock notice", "notice_unlocked_" .. tostring(unlock))
					end
				end
				if step.sequence ~= nil then
					needSequence(stepWhere .. ".sequence", step.sequence)
				end
			end
			if step.kind == "phase" then
				if not PHASE_GOALS[step.goal] then
					fail("%s.goal '%s' must be unneededOff, shieldAim, dim, or time", stepWhere, tostring(step.goal))
				end
				if typeof(step.fixtures) ~= "table" or #step.fixtures == 0 then
					fail("%s needs a fixtures list", stepWhere)
				else
					for _, fixtureId in step.fixtures do
						if not fixtureIds[fixtureId] then
							fail("%s uses unknown fixture '%s'", stepWhere, tostring(fixtureId))
						end
					end
					if typeof(step.required) ~= "number" or step.required < 1 or step.required > #step.fixtures then
						fail("%s.required must be between 1 and the number of fixtures", stepWhere)
					end
				end
				if step.bossId ~= nil and configs.BossConfig[step.bossId] == nil then
					fail("%s.bossId '%s' is not in BossConfig", stepWhere, tostring(step.bossId))
				end
				if step.enterSequence ~= nil then
					needSequence(stepWhere .. ".enterSequence", step.enterSequence)
				end
			elseif step.kind == "claims" then
				if typeof(step.tipIds) ~= "table" or #step.tipIds == 0 then
					fail("%s needs tipIds", stepWhere)
				else
					for _, tipId in step.tipIds do
						if not tipIdSet[tipId] then
							fail("%s uses unknown tip '%s'", stepWhere, tostring(tipId))
						end
					end
				end
				if step.calmsBoss ~= nil and configs.BossConfig[step.calmsBoss] == nil then
					fail("%s.calmsBoss '%s' is not in BossConfig", stepWhere, tostring(step.calmsBoss))
				end
				if step.restoresZone ~= nil and zones[step.restoresZone] == nil then
					fail("%s.restoresZone '%s' is not a zone", stepWhere, tostring(step.restoresZone))
				end
				if step.enterSequence ~= nil then
					needSequence(stepWhere .. ".enterSequence", step.enterSequence)
				end
			elseif step.kind == "ending" then
				if world.Checkpoints[step.teleportTo] == nil then
					fail("%s.teleportTo '%s' is not a checkpoint", stepWhere, tostring(step.teleportTo))
				end
				needSequence(stepWhere .. ".sequence", step.sequence)
				needUIText(stepWhere .. ".achievement", "achievement_" .. tostring(step.achievement))
			end
			if step.companions ~= nil and world.CompanionStations[step.companions] == nil then
				fail("%s.companions '%s' is not in WorldConfig.CompanionStations", stepWhere, tostring(step.companions))
			end
			if step.activeZone ~= nil and zones[step.activeZone] == nil then
				fail("%s.activeZone '%s' is not a zone", stepWhere, tostring(step.activeZone))
			end
		end
	end
	needUIText("MissionConfig.FreeRoamObjectiveKey", configs.MissionConfig.FreeRoamObjectiveKey)

	-- World
	for stationId, station in configs.WorldConfig.CompanionStations do
		for _, friend in { "Aadi", "Aditya", "Adrika" } do
			if typeof(station[friend]) ~= "Vector3" and typeof(station[friend]) ~= "table" then
				fail("WorldConfig.CompanionStations.%s is missing %s", stationId, friend)
			end
		end
	end
	for index, sign in configs.WorldConfig.Signposts do
		needUIText(string.format("WorldConfig.Signposts[%d]", index), sign.textKey)
	end
	for id, interactable in configs.WorldConfig.Interactables do
		needUIText("WorldConfig.Interactables." .. id .. ".actionKey", interactable.actionKey)
		needUIText("WorldConfig.Interactables." .. id .. ".objectKey", interactable.objectKey)
	end

	-- Quizzes: localized text, valid answers, preset choices only.
	for quizId, quiz in quizzes.Quizzes do
		local where = "QuizConfig.Quizzes." .. quizId
		needUIText(where .. ".titleKey", quiz.titleKey)
		needUIText(where .. ".introKey", quiz.introKey)
		local set = quizzes.QuestionSets[quiz.questionSet]
		if typeof(set) ~= "table" or #set == 0 then
			fail("%s.questionSet '%s' has no questions", where, tostring(quiz.questionSet))
			continue
		end
		for index, question in set do
			local qWhere = string.format("QuizConfig.QuestionSets.%s[%d]", quiz.questionSet, index)
			checkLocalized(qWhere .. ".question", question.question, ConfigValidator.MaxDialogueCharacters)
			if typeof(question.choices) ~= "table" or #question.choices < 2 then
				fail("%s needs at least 2 choices", qWhere)
			else
				for choiceIndex, choice in question.choices do
					checkLocalized(string.format("%s.choices[%d]", qWhere, choiceIndex), choice, 60)
				end
				if typeof(question.correct) ~= "number" or question.correct < 1 or question.correct > #question.choices then
					fail("%s.correct must be a choice number", qWhere)
				end
			end
		end
	end

	-- Night Sky Pledge
	local pledge = configs.PledgeConfig
	local actionIds: { [string]: boolean } = {}
	for _, category in pledge.Categories or {} do
		needUIText("PledgeConfig category " .. tostring(category), "pledge_cat_" .. tostring(category))
		local actions = pledge.Actions[category]
		if typeof(actions) ~= "table" or #actions == 0 then
			fail("PledgeConfig.Actions.%s needs at least one action", tostring(category))
			continue
		end
		for index, action in actions do
			local where = string.format("PledgeConfig.Actions.%s[%d]", category, index)
			if typeof(action.id) ~= "string" or actionIds[action.id] or #action.id > 40 then
				fail("%s needs a unique id (40 characters max)", where)
			else
				actionIds[action.id] = true
			end
			checkLocalized(where, action.text, 100)
			local text = if typeof(action.text) == "table" then string.lower(tostring(action.text[experience.DefaultLocale])) else ""
			-- Safety wording check: children must never be told to handle fixtures.
			for _, unsafe in { "climb", "unscrew", "rewire", "touch the" } do
				if string.find(text, unsafe, 1, true) then
					fail("%s must not ask players to %s anything", where, unsafe)
				end
			end
		end
	end

	-- Companion site URL: empty until deployed, then an https address (never guessed).
	local siteUrl = experience.CompanionSiteUrl
	if siteUrl ~= nil and siteUrl ~= "" and (typeof(siteUrl) ~= "string" or string.match(siteUrl, "^https://[%w%.%-/_]+$") == nil) then
		fail("ExperienceConfig.CompanionSiteUrl must be \"\" or a plain https:// address")
	end

	-- Community report content
	local report = configs.ReportConfig
	if report ~= nil then
		for placeId, place in report.Places or {} do
			local where = "ReportConfig.Places." .. placeId
			if zones[placeId] == nil then
				fail("%s is not a zone", where)
			end
			for _, field in { "location", "fixture", "problem", "essential" } do
				checkLocalized(where .. "." .. field, place[field], 120)
			end
			if typeof(place.alternatives) ~= "table" or #place.alternatives < 2 then
				fail("%s needs at least 2 alternatives", where)
			end
			local recIds: { [string]: boolean } = {}
			for index, recommendation in place.recommendations or {} do
				if typeof(recommendation.id) ~= "string" or recIds[recommendation.id] then
					fail("%s.recommendations[%d] needs a unique id", where, index)
				else
					recIds[recommendation.id] = true
				end
				checkLocalized(string.format("%s.recommendations[%d]", where, index), recommendation.text, 120)
			end
		end
		for index, reflection in report.Reflections or {} do
			checkLocalized(string.format("ReportConfig.Reflections[%d]", index), reflection.text, 120)
		end
	end

	-- Analytics events must be plain snake_case names.
	for eventName in configs.AnalyticsConfig.Events or {} do
		if typeof(eventName) ~= "string" or not string.match(eventName, "^[a-z][a-z0-9_]*$") then
			fail("AnalyticsConfig event '%s' must be lowercase snake_case", tostring(eventName))
		end
	end

	return { errors = errors, warnings = warnings }
end

return ConfigValidator
