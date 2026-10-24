--!strict
-- DevService: developer test tools (reset world, reset own save).
-- Every request is checked on the server: feature flag, environment (never production),
-- authorized developer, valid action, and the typed confirm word. Clients only see the
-- tools when the server marks them authorized; hiding the UI is not the protection.

local Players = game:GetService("Players")

local DevConfig = require(script.Parent.Parent:WaitForChild("ServerConfig"):WaitForChild("DevConfig"))
local Environment = require(script.Parent:WaitForChild("Environment"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))
local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local NavigationService = require(script.Parent:WaitForChild("NavigationService"))

local ConfigFolder = game:GetService("ReplicatedStorage"):WaitForChild("DarkSky"):WaitForChild("Config")
local MissionConfig = require(ConfigFolder:WaitForChild("MissionConfig"))
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))

-- Where a jumped-to mission begins: next to the friends' first station in that mission.
local function missionStart(missionId: string): Vector3?
	for _, mission in MissionConfig.Missions do
		if mission.id == missionId then
			for _, step in mission.steps do
				local station = step.companions and (WorldConfig.CompanionStations :: any)[step.companions]
				if station then
					return station.Aditya + Vector3.new(6, 0.5, 6)
				end
			end
		end
	end
	return nil
end

local DevService = {}

local VALID_ACTIONS = { resetWorld = true, resetProfile = true, jumpMission = true }

local function markPlayer(player: Player)
	player:SetAttribute("DarkSkyDeveloper", Environment.isDeveloper(player))
end

function DevService.init(remotes: { [string]: RemoteEvent })
	local kind = Environment.kind()
	WorldStateService.setAttribute("Environment", kind)
	WorldStateService.setAttribute("ResetConfirmWord", if kind ~= "production" then DevConfig.ResetConfirmWord else nil)

	Players.PlayerAdded:Connect(markPlayer)
	for _, player in Players:GetPlayers() do
		markPlayer(player)
	end

	RemoteGuard.connect(remotes.DevRequest, "DevRequest", function(player: Player, action: any, confirm: any, missionId: any)
		if typeof(action) ~= "string" or not VALID_ACTIONS[action] or typeof(confirm) ~= "string" then
			return
		end
		if not Environment.isDeveloper(player) or Environment.kind() == "production" then
			warn(string.format("[DarkSky] Dev request refused for user %d (%s)", player.UserId, Environment.kind()))
			FixturePuzzleService.notify(player, "notice_dev_denied")
			return
		end
		if confirm ~= DevConfig.ResetConfirmWord then
			FixturePuzzleService.notify(player, "notice_dev_confirm")
			return
		end
		if action == "jumpMission" then
			if typeof(missionId) ~= "string" or #missionId > 40 then
				return
			end
			print(string.format("[DarkSky] DEV: jump to mission %s by user %d", missionId, player.UserId))
			if ProgressionService.jumpToMission(missionId) then
				local start = missionStart(missionId)
				if start then
					for _, other in Players:GetPlayers() do
						NavigationService.teleport(other, start)
					end
				end
			end
		elseif action == "resetWorld" then
			print(string.format("[DarkSky] DEV: world reset by user %d", player.UserId))
			ProgressionService.resetWorld()
		else
			print(string.format("[DarkSky] DEV: profile reset for user %d in %s", player.UserId, Environment.kind()))
			ProfileService.resetProfile(player)
			FixturePuzzleService.notify(player, "notice_profile_reset")
		end
	end)
end

return DevService
