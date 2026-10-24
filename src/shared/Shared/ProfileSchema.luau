--!strict
-- ProfileSchema: the saved player profile, its defaults, migrations, and repair rules.
-- Pure (no DataStore calls) so every case can be tested from the command line.
--
-- Stored data contains NO names, chat, free text, locations, or other personal details:
-- only progress flags, counts, preset choices, and game-generated journal entries.
--
-- Version history:
--   0  hypothetical unversioned data (no schemaVersion field)
--   1  first saved format (Stage B): checkpoints were step numbers
--   2  Stage C: checkpoints are step ids; `unlocks` (luxLens, journal, bike);
--      the old "leo_slice" mission became "act1" + "leo"

local ProfileSchema = {}

ProfileSchema.CurrentVersion = 2
ProfileSchema.MaxJournalEntries = 300

export type JournalEntry = {
	id: string, -- unique, e.g. "realm:Leo"; used to avoid duplicates
	kind: string, -- "realm" | "evidence" | "moonTip" | "note"
	key: string, -- zone id, evidence key, tip id...
	at: number, -- os.time() when recorded
	data: { [string]: any }?, -- small numbers/booleans/strings from game data only
}

export type Profile = {
	schemaVersion: number,
	completedMissions: { [string]: boolean },
	checkpoints: { [string]: string }, -- missionId -> step id reached
	unlocks: { [string]: boolean }, -- tools and items: luxLens, journal, bike
	restoredZones: { [string]: boolean },
	doubtTokens: number,
	journal: { JournalEntry },
	achievements: { [string]: boolean },
	quiz: { [string]: number }, -- "pre"/"post" -> score
	pledge: { [string]: { string } }, -- category -> preset action ids
	stats: { [string]: number },
}

function ProfileSchema.default(): Profile
	return {
		schemaVersion = ProfileSchema.CurrentVersion,
		completedMissions = {},
		checkpoints = {},
		unlocks = {},
		restoredZones = {},
		doubtTokens = 0,
		journal = {},
		achievements = {},
		quiz = {},
		pledge = {},
		stats = { sessions = 0 },
	}
end

-- Each function upgrades data from version N to N + 1.
local migrations: { [number]: (any) -> any } = {
	[0] = function(data)
		-- Unversioned data: keep any recognizable fields, sanitize does the rest.
		data.schemaVersion = 1
		return data
	end,
	[1] = function(data)
		-- Step numbers are not stable when missions change; drop them (missions restart
		-- at their first step, completed missions stay completed).
		data.checkpoints = {}
		data.unlocks = {}
		local completed = if typeof(data.completedMissions) == "table" then data.completedMissions else {}
		if completed.leo_slice == true then
			-- Players who finished the original Leo slice already had the tools and fixed
			-- the tutorial street equivalent.
			completed.leo_slice = nil
			completed.act1 = true
			completed.leo = true
			data.unlocks = { luxLens = true, journal = true, bike = true }
			if typeof(data.restoredZones) == "table" then
				data.restoredZones.Home = true
			end
		end
		data.completedMissions = completed
		data.schemaVersion = 2
		return data
	end,
}

local function boolMap(value: any, repairs: { string }, field: string): { [string]: boolean }
	local result = {}
	if typeof(value) ~= "table" then
		if value ~= nil then
			table.insert(repairs, field .. " was not a table")
		end
		return result
	end
	for key, flag in value do
		if typeof(key) == "string" and flag == true then
			result[key] = true
		end
	end
	return result
end

local function numberMap(value: any, repairs: { string }, field: string): { [string]: number }
	local result = {}
	if typeof(value) ~= "table" then
		if value ~= nil then
			table.insert(repairs, field .. " was not a table")
		end
		return result
	end
	for key, number in value do
		if typeof(key) == "string" and typeof(number) == "number" and number == number then
			result[key] = number
		end
	end
	return result
end

local function cleanData(value: any): { [string]: any }?
	if typeof(value) ~= "table" then
		return nil
	end
	local result = {}
	for key, item in value do
		local itemType = typeof(item)
		if typeof(key) == "string" and (itemType == "number" or itemType == "boolean" or (itemType == "string" and #item <= 80)) then
			result[key] = item
		end
	end
	return result
end

local function stringMap(value: any, repairs: { string }, field: string): { [string]: string }
	local result = {}
	if typeof(value) ~= "table" then
		if value ~= nil then
			table.insert(repairs, field .. " was not a table")
		end
		return result
	end
	for key, text in value do
		if typeof(key) == "string" and typeof(text) == "string" and #text <= 40 then
			result[key] = text
		end
	end
	return result
end

local function journalList(value: any, repairs: { string }): { JournalEntry }
	local result: { JournalEntry } = {}
	if typeof(value) ~= "table" then
		if value ~= nil then
			table.insert(repairs, "journal was not a table")
		end
		return result
	end
	local seen = {}
	for _, entry in value do
		if typeof(entry) == "table"
			and typeof(entry.id) == "string"
			and typeof(entry.kind) == "string"
			and typeof(entry.key) == "string"
			and not seen[entry.id]
		then
			seen[entry.id] = true
			table.insert(result, {
				id = entry.id,
				kind = entry.kind,
				key = entry.key,
				at = if typeof(entry.at) == "number" then entry.at else 0,
				data = cleanData(entry.data),
			})
		end
	end
	-- Keep the newest entries if the journal ever grows past the cap.
	while #result > ProfileSchema.MaxJournalEntries do
		table.remove(result, 1)
		table.insert(repairs, "journal trimmed")
	end
	return result
end

local function pledgeMap(value: any): { [string]: { string } }
	local result = {}
	if typeof(value) ~= "table" then
		return result
	end
	for category, actions in value do
		if typeof(category) == "string" and typeof(actions) == "table" then
			local list = {}
			for _, actionId in actions do
				if typeof(actionId) == "string" and #actionId <= 40 then
					table.insert(list, actionId)
				end
			end
			result[category] = list
		end
	end
	return result
end

-- Turns stored data into a valid current profile.
-- Returns (profile, repairs) on success, or (nil, reason) when the data must NOT be
-- overwritten ("newer" = saved by a newer game version) or is unusable ("corrupt").
function ProfileSchema.migrate(raw: any): (Profile?, { string } | string)
	if typeof(raw) ~= "table" then
		return nil, "corrupt"
	end
	local version = raw.schemaVersion
	if version == nil then
		version = 0
	end
	if typeof(version) ~= "number" or version ~= math.floor(version) or version < 0 then
		return nil, "corrupt"
	end
	if version > ProfileSchema.CurrentVersion then
		return nil, "newer"
	end

	local data = table.clone(raw)
	while version < ProfileSchema.CurrentVersion do
		local step = migrations[version]
		if step == nil then
			return nil, "corrupt"
		end
		data = step(data)
		version += 1
	end

	local repairs: { string } = {}
	local tokens = data.doubtTokens
	if typeof(tokens) ~= "number" or tokens ~= tokens or tokens < 0 then
		if tokens ~= nil then
			table.insert(repairs, "doubtTokens invalid")
		end
		tokens = 0
	end
	local profile: Profile = {
		schemaVersion = ProfileSchema.CurrentVersion,
		completedMissions = boolMap(data.completedMissions, repairs, "completedMissions"),
		checkpoints = stringMap(data.checkpoints, repairs, "checkpoints"),
		unlocks = boolMap(data.unlocks, repairs, "unlocks"),
		restoredZones = boolMap(data.restoredZones, repairs, "restoredZones"),
		doubtTokens = math.floor(tokens),
		journal = journalList(data.journal, repairs),
		achievements = boolMap(data.achievements, repairs, "achievements"),
		quiz = numberMap(data.quiz, repairs, "quiz"),
		pledge = pledgeMap(data.pledge),
		stats = numberMap(data.stats, repairs, "stats"),
	}
	return profile, repairs
end

-- Adds a journal entry unless one with the same id exists. Returns true if added.
function ProfileSchema.addJournalEntry(profile: Profile, entry: JournalEntry): boolean
	for _, existing in profile.journal do
		if existing.id == entry.id then
			return false
		end
	end
	table.insert(profile.journal, entry)
	while #profile.journal > ProfileSchema.MaxJournalEntries do
		table.remove(profile.journal, 1)
	end
	return true
end

return ProfileSchema
