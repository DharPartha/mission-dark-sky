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

local DevService = {}

local VALID_ACTIONS = { resetWorld = true, resetProfile = true }

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

	RemoteGuard.connect(remotes.DevRequest, "DevRequest", function(player: Player, action: any, confirm: any)
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
		if action == "resetWorld" then
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
