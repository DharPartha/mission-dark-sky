--!strict
-- ProfileStore: load and save one player's profile safely through any store that has
-- UpdateAsync(key, transform) and SetAsync(key, value) (a Roblox DataStore, the memory
-- store below, or a fake store in tests).
--
-- Safety rules (from the build spec):
--   * A failed read NEVER leads to writing defaults over a real save. The player plays
--     "unsaved" for that session instead.
--   * A save made by a newer game version is never overwritten.
--   * Unreadable (corrupt) data is backed up to a separate key before a fresh profile
--     replaces it; if the backup fails, the player plays unsaved.
--   * Session locks stop two servers writing the same profile.
--   * Retries use exponential backoff.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared")
local ProfileSchema = require(SharedFolder:WaitForChild("ProfileSchema"))
local SessionLock = require(SharedFolder:WaitForChild("SessionLock"))

local ProfileStore = {}
ProfileStore.__index = ProfileStore

export type Store = {
	UpdateAsync: (self: any, key: string, transform: (any) -> any) -> any,
	SetAsync: (self: any, key: string, value: any) -> any,
}

export type Options = {
	store: Store,
	jobId: string,
	now: () -> number,
	wait: (seconds: number) -> (),
	staleLockSeconds: number,
	maxAttempts: number,
	baseBackoffSeconds: number,
}

export type LoadStatus = "loaded" | "new" | "unsaved"
export type LoadResult = {
	status: LoadStatus,
	profile: ProfileSchema.Profile,
	reason: string?, -- why unsaved, or repairs made
}

export type SaveResult = "saved" | "lock_lost" | "failed"

export type ProfileStoreObject = typeof(setmetatable({} :: { options: Options }, ProfileStore))

function ProfileStore.new(options: Options): ProfileStoreObject
	return setmetatable({ options = options }, ProfileStore)
end

local function backoff(options: Options, attempt: number)
	options.wait(options.baseBackoffSeconds * 2 ^ (attempt - 1))
end

function ProfileStore.load(self: ProfileStoreObject, key: string): LoadResult
	local options = self.options
	local replaceCorrupt = false
	local lastReason = "read_failed"

	for attempt = 1, options.maxAttempts do
		local outcome = "none"
		local repairs: { string } = {}
		local corruptRaw: any = nil
		local loadedProfile: ProfileSchema.Profile? = nil
		local now = options.now()

		local ok, err = pcall(function()
			options.store:UpdateAsync(key, function(current: any): any
				-- UpdateAsync may call this more than once; reset per call.
				outcome = "none"
				local record = SessionLock.unwrap(current)
				if record == nil then
					outcome = "new"
					loadedProfile = ProfileSchema.default()
					return SessionLock.wrap(loadedProfile, options.jobId, now)
				end
				local lockState = SessionLock.evaluate(record, options.jobId, now, options.staleLockSeconds)
				if lockState == "held" then
					outcome = "locked"
					return nil
				end
				local profile, detail = ProfileSchema.migrate(record.profile)
				if profile == nil then
					if detail == "newer" then
						outcome = "newer"
						return nil
					end
					if not replaceCorrupt then
						outcome = "corrupt"
						corruptRaw = record.profile
						return nil
					end
					outcome = "new"
					loadedProfile = ProfileSchema.default()
					return SessionLock.wrap(loadedProfile, options.jobId, now)
				end
				outcome = "loaded"
				repairs = detail :: { string }
				loadedProfile = profile
				return SessionLock.wrap(profile, options.jobId, now)
			end)
		end)

		if ok then
			if (outcome == "loaded" or outcome == "new") and loadedProfile then
				return {
					status = outcome :: LoadStatus,
					profile = loadedProfile :: ProfileSchema.Profile,
					reason = if #repairs > 0 then table.concat(repairs, "; ") else nil,
				}
			elseif outcome == "newer" then
				return { status = "unsaved", profile = ProfileSchema.default(), reason = "saved_by_newer_version" }
			elseif outcome == "corrupt" then
				-- Keep a copy of the unreadable data before replacing it.
				local backupOk = pcall(function()
					options.store:SetAsync(key .. "_backup_" .. tostring(now), { raw = corruptRaw })
				end)
				if not backupOk then
					return { status = "unsaved", profile = ProfileSchema.default(), reason = "corrupt_backup_failed" }
				end
				replaceCorrupt = true
				lastReason = "corrupt"
				-- Retry immediately; the next attempt writes a fresh profile.
				continue
			elseif outcome == "locked" then
				lastReason = "locked_by_other_server"
			end
		else
			lastReason = "read_failed: " .. tostring(err)
		end
		if attempt < options.maxAttempts then
			backoff(options, attempt)
		end
	end

	return { status = "unsaved", profile = ProfileSchema.default(), reason = lastReason }
end

-- Saves the profile. With release = true the session lock is cleared (player leaving).
function ProfileStore.save(self: ProfileStoreObject, key: string, profile: ProfileSchema.Profile, release: boolean): SaveResult
	local options = self.options
	for attempt = 1, options.maxAttempts do
		local lockLost = false
		local now = options.now()
		local ok = pcall(function()
			options.store:UpdateAsync(key, function(current: any): any
				lockLost = false
				local record = SessionLock.unwrap(current)
				local lockState = SessionLock.evaluate(record, options.jobId, now, options.staleLockSeconds)
				if lockState == "held" then
					-- Another server took over this profile; do not overwrite its data.
					lockLost = true
					return nil
				end
				return SessionLock.wrap(profile, if release then nil else options.jobId, now)
			end)
		end)
		if ok then
			return if lockLost then "lock_lost" else "saved"
		end
		if attempt < options.maxAttempts then
			backoff(options, attempt)
		end
	end
	return "failed"
end

-- In-memory store with the same API, used when real DataStores are unavailable
-- (unpublished Studio file). Data disappears when the server stops.
function ProfileStore.newMemoryStore(): Store
	local data: { [string]: any } = {}
	local store = {}
	function store.UpdateAsync(_self: any, key: string, transform: (any) -> any): any
		local result = transform(data[key])
		if result ~= nil then
			data[key] = result
		end
		return result
	end
	function store.SetAsync(_self: any, key: string, value: any): any
		data[key] = value
		return nil
	end
	return store :: any
end

return ProfileStore
