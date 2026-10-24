--!strict
-- ProfileService: personal, saved progress for each player (missions, realms, journal,
-- Doubt Tokens, achievements, quiz, pledge). Uses ProfileStore for safe DataStore access.
--
-- Save status shown to the player (attribute SaveStatus on Player.DarkSkyProfile):
--   loading   still reading
--   loaded    real save loaded; saves automatically
--   new       first time; a new save was created
--   memory    local Studio file or persistence off: progress lasts until the server stops
--   unsaved   the save could not be read safely; nothing will be written this session
--   lock_lost another server took the save; writing stopped here
--
-- Writes happen at checkpoints (throttled), on an autosave timer, when the player leaves,
-- and when the server shuts down.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local SharedFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared")
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local ProfileSchema = require(SharedFolder:WaitForChild("ProfileSchema"))
local DevConfig = require(script.Parent.Parent:WaitForChild("ServerConfig"):WaitForChild("DevConfig"))
local ProfileStore = require(script.Parent.Parent:WaitForChild("Persistence"):WaitForChild("ProfileStore"))
local Environment = require(script.Parent:WaitForChild("Environment"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))

local ProfileService = {}

type Session = {
	profile: ProfileSchema.Profile,
	status: string,
	canSave: boolean,
	lastSaveAt: number,
	saving: boolean,
	savePending: boolean,
	folder: Folder,
	journalValue: StringValue,
}

local FOLDER_NAME = "DarkSkyProfile"

local store: ProfileStore.ProfileStoreObject
local storeMode: "datastore" | "memory" | "unavailable" = "memory"
local sessions: { [Player]: Session } = {}
-- Team rewards that happened while a player's save was still loading; applied on load.
local pendingRewards: { [Player]: { (profile: ProfileSchema.Profile, player: Player) -> () } } = {}
local MAX_PENDING_REWARDS = 50
local loadedEvent = Instance.new("BindableEvent")
local shuttingDown = false

local function keyFor(player: Player): string
	return "player_" .. tostring(player.UserId)
end

local function replicate(player: Player)
	local session = sessions[player]
	if session == nil then
		return
	end
	local profile = session.profile
	local folder = session.folder
	folder:SetAttribute("SaveStatus", session.status)
	folder:SetAttribute("DoubtTokens", profile.doubtTokens)
	local restored = {}
	for zoneId in profile.restoredZones do
		table.insert(restored, zoneId)
	end
	table.sort(restored)
	folder:SetAttribute("RestoredZones", table.concat(restored, ","))
	local unlocks = {}
	for unlock in profile.unlocks do
		table.insert(unlocks, unlock)
	end
	table.sort(unlocks)
	-- Comma-separated, wrapped in commas so clients can search for ",bike,".
	folder:SetAttribute("Unlocks", "," .. table.concat(unlocks, ",") .. ",")
	for quizId, score in profile.quiz do
		folder:SetAttribute("Quiz_" .. quizId, score)
	end
	local achievements = {}
	for achievement in profile.achievements do
		table.insert(achievements, achievement)
	end
	table.sort(achievements)
	folder:SetAttribute("Achievements", "," .. table.concat(achievements, ",") .. ",")
	for name in ProfileSchema.SettingValues do
		folder:SetAttribute("Setting_" .. name, profile.settings[name])
	end
	local pledgeOk, pledgeJson = pcall(HttpService.JSONEncode, HttpService, profile.pledge)
	folder:SetAttribute("PledgeJson", if pledgeOk then pledgeJson else "{}")
	local ok, json = pcall(HttpService.JSONEncode, HttpService, profile.journal)
	session.journalValue.Value = if ok then json else "[]"
end

local function doSave(player: Player, release: boolean)
	local session = sessions[player]
	if session == nil or not session.canSave then
		return
	end
	if session.saving then
		if not release then
			session.savePending = true
			return
		end
		-- A leaving player's final save must not be skipped: wait for the current write.
		local started = os.clock()
		while session.saving and os.clock() - started < 15 do
			task.wait(0.1)
		end
	end
	session.saving = true
	session.lastSaveAt = os.clock()
	local result = store:save(keyFor(player), session.profile, release)
	session.saving = false
	if result == "lock_lost" then
		session.canSave = false
		session.status = "lock_lost"
		replicate(player)
		warn(string.format("[DarkSky] Save lock lost for user %d; saving stopped on this server", player.UserId))
	elseif result == "failed" then
		warn(string.format("[DarkSky] Save failed for user %d; will retry at next checkpoint", player.UserId))
	end
	if session.savePending and not release then
		session.savePending = false
		task.defer(doSave, player, false)
	end
end

local function onPlayerAdded(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder:SetAttribute("SaveStatus", "loading")
	local journalValue = Instance.new("StringValue")
	journalValue.Name = "JournalJson"
	journalValue.Value = "[]"
	journalValue.Parent = folder
	folder.Parent = player

	local result = store:load(keyFor(player))
	if player.Parent ~= Players then
		-- Left while loading: release the lock we just took so the next server can load.
		if result.status ~= "unsaved" and storeMode == "datastore" then
			store:save(keyFor(player), result.profile, true)
		end
		return
	end

	local status: string = result.status
	local canSave = result.status ~= "unsaved"
	if storeMode == "memory" then
		status = "memory"
	elseif storeMode == "unavailable" then
		status = "unsaved"
		canSave = false
	end
	if status == "unsaved" then
		warn(string.format("[DarkSky] Playing unsaved for user %d: %s", player.UserId, tostring(result.reason)))
		MetricsService.log(player, "save_unavailable")
	elseif result.reason then
		print(string.format("[DarkSky] Save repaired for user %d: %s", player.UserId, result.reason))
	end

	result.profile.stats.sessions = (result.profile.stats.sessions or 0) + 1
	-- Rewards the team earned while this save was loading.
	for _, reward in pendingRewards[player] or {} do
		reward(result.profile, player)
	end
	pendingRewards[player] = nil
	sessions[player] = {
		profile = result.profile,
		status = status,
		canSave = canSave,
		lastSaveAt = 0,
		saving = false,
		savePending = false,
		folder = folder,
		journalValue = journalValue,
	}
	replicate(player)
	MetricsService.log(player, "session_start")
	loadedEvent:Fire(player)

	-- A read that failed or was blocked by another server's lock can succeed later:
	-- keep retrying and merge this session's progress into the real save (nothing lost).
	if status == "unsaved" and storeMode == "datastore" and result.reason ~= "saved_by_newer_version" then
		task.spawn(function()
			for _ = 1, DevConfig.RecoveryAttempts do
				task.wait(DevConfig.RecoveryRetrySeconds)
				local session = sessions[player]
				if session == nil or session.canSave then
					return
				end
				local retry = store:load(keyFor(player))
				if player.Parent ~= Players then
					if retry.status ~= "unsaved" then
						store:save(keyFor(player), ProfileSchema.merge(retry.profile, session.profile), true)
					end
					return
				end
				if retry.status ~= "unsaved" then
					session.profile = ProfileSchema.merge(retry.profile, session.profile)
					session.canSave = true
					session.status = "loaded"
					replicate(player)
					print(string.format("[DarkSky] Save recovered for user %d; session progress merged", player.UserId))
					task.spawn(doSave, player, false)
					return
				end
			end
		end)
	end
end

function ProfileService.init()
	local kind = Environment.kind()
	local backing: ProfileStore.Store
	if not FeatureFlags.EnablePersistence or kind == "local" then
		backing = ProfileStore.newMemoryStore()
		storeMode = "memory"
	else
		local scope = (DevConfig.DataScopes :: any)[kind] or "prod"
		local ok, dataStore = pcall(function()
			return DataStoreService:GetDataStore(DevConfig.DataStoreName, scope)
		end)
		if ok and dataStore then
			backing = dataStore :: any
			storeMode = "datastore"
		else
			-- No DataStore access (e.g. Studio API access off): never pretend to save.
			warn("[DarkSky] DataStore unavailable: " .. tostring(dataStore))
			backing = ProfileStore.newMemoryStore()
			storeMode = "unavailable"
		end
	end
	print(string.format("[DarkSky] Environment %s, saves: %s", kind, storeMode))

	local jobId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
	store = ProfileStore.new({
		store = backing,
		jobId = jobId,
		now = os.time,
		wait = function(seconds: number)
			task.wait(seconds)
		end,
		staleLockSeconds = DevConfig.StaleLockSeconds,
		maxAttempts = DevConfig.MaxAttempts,
		baseBackoffSeconds = DevConfig.BaseBackoffSeconds,
	})

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		pendingRewards[player] = nil
		if not shuttingDown then
			doSave(player, true)
		end
		sessions[player] = nil
	end)

	game:BindToClose(function()
		shuttingDown = true
		local pending = 0
		for player in sessions do
			pending += 1
			task.spawn(function()
				doSave(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.5)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(DevConfig.AutosaveSeconds)
			for player in sessions do
				task.spawn(doSave, player, false)
			end
		end
	end)
end

function ProfileService.getProfile(player: Player): ProfileSchema.Profile?
	local session = sessions[player]
	return if session then session.profile else nil
end

-- Waits until the player's profile is loaded (or timeout). Returns nil if it never loads.
function ProfileService.waitForProfile(player: Player, timeoutSeconds: number): ProfileSchema.Profile?
	local started = os.clock()
	while sessions[player] == nil and player.Parent == Players and os.clock() - started < timeoutSeconds do
		task.wait(0.1)
	end
	return ProfileService.getProfile(player)
end

function ProfileService.onLoaded(callback: (player: Player) -> ())
	loadedEvent.Event:Connect(callback)
end

-- Changes a profile. The callback edits it in place; the client view updates right away.
function ProfileService.update(player: Player, mutate: (profile: ProfileSchema.Profile) -> ())
	local session = sessions[player]
	if session == nil then
		return
	end
	mutate(session.profile)
	replicate(player)
end

-- Applies a change to every loaded player in the server (team rewards).
function ProfileService.updateAll(mutate: (profile: ProfileSchema.Profile, player: Player) -> ())
	for player, session in sessions do
		mutate(session.profile, player)
		replicate(player)
	end
	-- Players present but still loading get the reward when their save arrives.
	for _, player in Players:GetPlayers() do
		if sessions[player] == nil then
			local queue = pendingRewards[player] or {}
			if #queue < MAX_PENDING_REWARDS then
				table.insert(queue, mutate)
			end
			pendingRewards[player] = queue
		end
	end
end

-- Saves accessibility and graphics choices so they follow the player between sessions.
function ProfileService.saveSettings(player: Player, settings: any)
	local clean = ProfileSchema.cleanSettings(settings)
	ProfileService.update(player, function(profile)
		for name, value in clean do
			profile.settings[name] = value
		end
	end)
	ProfileService.checkpoint(player)
end

-- Requests a save soon; checkpoints close together are merged into one write.
function ProfileService.checkpoint(player: Player)
	local session = sessions[player]
	if session == nil or not session.canSave then
		return
	end
	local waitFor = DevConfig.MinSecondsBetweenSaves - (os.clock() - session.lastSaveAt)
	if waitFor <= 0 then
		task.spawn(doSave, player, false)
	elseif not session.savePending then
		session.savePending = true
		task.delay(waitFor, function()
			local current = sessions[player]
			if current and current.savePending and not current.saving then
				current.savePending = false
				doSave(player, false)
			end
		end)
	end
end

function ProfileService.checkpointAll()
	for player in sessions do
		ProfileService.checkpoint(player)
	end
end

function ProfileService.hasUnlock(player: Player, unlock: string): boolean
	local profile = ProfileService.getProfile(player)
	return profile ~= nil and profile.unlocks[unlock] == true
end

-- Developer test reset of one player's save. Callers must check Environment first.
function ProfileService.resetProfile(player: Player)
	local session = sessions[player]
	if session == nil then
		return
	end
	session.profile = ProfileSchema.default()
	for name in session.folder:GetAttributes() do
		if string.sub(name, 1, 5) == "Quiz_" then
			session.folder:SetAttribute(name, nil)
		end
	end
	replicate(player)
	if session.canSave then
		task.spawn(doSave, player, false)
	end
end

return ProfileService
