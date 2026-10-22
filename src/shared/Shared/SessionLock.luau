--!strict
-- SessionLock: decides who may write a saved profile, so two servers never overwrite
-- each other (for example when a player quickly hops servers). Pure and testable.
--
-- A stored record looks like:
--   { darkSkyRecord = 1, profile = <profile data>, lock = { jobId = "...", at = <os.time> } | nil }
-- Older data without the wrapper is treated as an unlocked profile.

local SessionLock = {}

export type Lock = { jobId: string, at: number }
export type Record = { darkSkyRecord: number, profile: any, lock: Lock? }
export type LockState = "free" | "ours" | "held" | "stale"

function SessionLock.unwrap(stored: any): Record?
	if stored == nil then
		return nil
	end
	if typeof(stored) == "table" and stored.darkSkyRecord == 1 then
		local lock = stored.lock
		if typeof(lock) ~= "table" or typeof(lock.jobId) ~= "string" or typeof(lock.at) ~= "number" then
			lock = nil
		end
		return { darkSkyRecord = 1, profile = stored.profile, lock = lock }
	end
	-- Unwrapped legacy data (or garbage, which the schema will reject).
	return { darkSkyRecord = 1, profile = stored, lock = nil }
end

function SessionLock.evaluate(record: Record?, jobId: string, now: number, staleSeconds: number): LockState
	local lock = record and record.lock
	if lock == nil then
		return "free"
	end
	if lock.jobId == jobId then
		return "ours"
	end
	if now - lock.at > staleSeconds then
		-- The other server stopped refreshing its lock (crashed); safe to take over.
		return "stale"
	end
	return "held"
end

function SessionLock.wrap(profile: any, jobId: string?, now: number): Record
	return {
		darkSkyRecord = 1,
		profile = profile,
		lock = if jobId then { jobId = jobId, at = now } else nil,
	}
end

return SessionLock
