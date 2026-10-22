--!strict
-- RemoteGuard: every client -> server RemoteEvent is connected through here.
-- It rate-limits each player per remote (Tuning.Remotes) and isolates handler errors,
-- so a malformed or spammed request is dropped instead of breaking the server.
-- Handlers still validate their own argument types, ranges, distance, and state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local Tuning = require(Root:WaitForChild("Config"):WaitForChild("Tuning"))
local RateLimiter = require(Root:WaitForChild("Shared"):WaitForChild("RateLimiter"))

local RemoteGuard = {}

local limiters: { RateLimiter.Limiter } = {}
local droppedCounts: { [Player]: number } = {}

Players.PlayerRemoving:Connect(function(player)
	for _, limiter in limiters do
		limiter:forget(player)
	end
	droppedCounts[player] = nil
end)

function RemoteGuard.connect(remote: RemoteEvent, limitName: string, handler: (player: Player, ...any) -> ())
	local spec = (Tuning.Remotes :: any)[limitName] or { burst = 4, perSecond = 1 }
	local limiter = RateLimiter.new(spec.burst, spec.perSecond)
	table.insert(limiters, limiter)

	remote.OnServerEvent:Connect(function(player: Player, ...: any)
		if not limiter:allow(player, os.clock()) then
			local count = (droppedCounts[player] or 0) + 1
			droppedCounts[player] = count
			-- Log the first drop and then every 50th, so spam cannot flood the output.
			if count == 1 or count % 50 == 0 then
				warn(string.format("[DarkSky] Rate limit: dropped %s from user %d (%d total)", remote.Name, player.UserId, count))
			end
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(string.format("[DarkSky] %s handler error: %s", remote.Name, tostring(err)))
		end
	end)
end

return RemoteGuard
