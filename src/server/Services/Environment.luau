--!strict
-- Environment: which kind of server this is, and who may use developer test tools.
-- Fails closed: any place not listed as a dev place is treated as production.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeatureFlags = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config"):WaitForChild("FeatureFlags"))
local DevConfig = require(script.Parent.Parent:WaitForChild("ServerConfig"):WaitForChild("DevConfig"))

local Environment = {}

export type Kind = "local" | "dev" | "production"

function Environment.kind(): Kind
	if game.PlaceId == 0 then
		-- An unpublished file can only run in Studio on the developer's own machine.
		return "local"
	end
	if table.find(DevConfig.DevPlaceIds, game.PlaceId) then
		return "dev"
	end
	return "production"
end

-- Test tools: never in production; anyone in a local Studio file; listed users in dev.
function Environment.isDeveloper(player: Player): boolean
	if not FeatureFlags.EnableTestReset then
		return false
	end
	local kind = Environment.kind()
	if kind == "local" then
		return RunService:IsStudio()
	elseif kind == "dev" then
		return table.find(DevConfig.DevUserIds, player.UserId) ~= nil
	end
	return false
end

return Environment
