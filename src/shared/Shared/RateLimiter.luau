--!strict
-- RateLimiter: token bucket per key (one bucket per player per remote).
-- Pure: the caller passes the current time, so it is deterministic in tests.
-- A burst of `capacity` requests is allowed, then `refillPerSecond` on average.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type Bucket = { tokens: number, updatedAt: number }
export type Limiter = typeof(setmetatable(
	{} :: { capacity: number, refillPerSecond: number, buckets: { [any]: Bucket } },
	RateLimiter
))

function RateLimiter.new(capacity: number, refillPerSecond: number): Limiter
	return setmetatable({ capacity = capacity, refillPerSecond = refillPerSecond, buckets = {} }, RateLimiter)
end

-- Returns true and spends a token when the request is allowed.
function RateLimiter.allow(self: Limiter, key: any, now: number): boolean
	local bucket = self.buckets[key]
	if bucket == nil then
		bucket = { tokens = self.capacity, updatedAt = now }
		self.buckets[key] = bucket
	end
	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.tokens = math.min(self.capacity, bucket.tokens + elapsed * self.refillPerSecond)
	bucket.updatedAt = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

-- Frees memory when a player leaves.
function RateLimiter.forget(self: Limiter, key: any)
	self.buckets[key] = nil
end

return RateLimiter
