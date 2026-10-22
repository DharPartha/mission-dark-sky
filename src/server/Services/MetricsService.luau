--!strict
-- MetricsService: anonymous aggregate analytics. Only event names listed in
-- AnalyticsConfig are sent, with at most one number. No personal data, no free text.
-- In local Studio files events are printed instead of sent, so you can check them.

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local AnalyticsConfig = require(ConfigFolder:WaitForChild("AnalyticsConfig"))
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))

local MetricsService = {}

local isLocal = game.PlaceId == 0

function MetricsService.log(player: Player, eventName: string, value: number?)
	if not FeatureFlags.EnableAnalytics then
		return
	end
	if (AnalyticsConfig.Events :: any)[eventName] == nil then
		warn("[DarkSky] Analytics event not in AnalyticsConfig: " .. eventName)
		return
	end
	if isLocal then
		print(string.format("[DarkSky] analytics %s %s", eventName, if value then tostring(value) else ""))
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
	if not ok then
		warn("[DarkSky] Analytics failed: " .. tostring(err))
	end
end

return MetricsService
