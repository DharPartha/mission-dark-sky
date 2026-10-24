--!strict
-- PledgeService: the Night Sky Pledge. Each player picks at least one preset action per
-- place (Home, School, Community). Only action ids are saved; no free text, no names.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared")
local ProfileSchema = require(SharedFolder:WaitForChild("ProfileSchema"))
local PledgeRules = require(SharedFolder:WaitForChild("PledgeRules"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))
local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))

local PledgeService = {}

local listeners: { (player: Player) -> () } = {}

-- Validation lives in Shared/PledgeRules so it can be tested from the command line.
PledgeService.clean = PledgeRules.clean

function PledgeService.hasPledged(player: Player): boolean
	local profile = ProfileService.getProfile(player)
	return profile ~= nil and next(profile.pledge) ~= nil
end

function PledgeService.everyonePledged(): boolean
	for _, player in Players:GetPlayers() do
		if ProfileService.getProfile(player) and not PledgeService.hasPledged(player) then
			return false
		end
	end
	return true
end

function PledgeService.setActive(active: boolean)
	WorldStateService.setAttribute("PledgeActive", active)
end

function PledgeService.onPledged(callback: (player: Player) -> ())
	table.insert(listeners, callback)
end

function PledgeService.init(remotes: { [string]: RemoteEvent })
	RemoteGuard.connect(remotes.PledgeSubmit, "PledgeSubmit", function(player: Player, choices: any)
		-- The pledge can be made (or remade) once it has been offered in the story.
		if WorldStateService.getAttribute("PledgeActive") ~= true and not PledgeService.hasPledged(player) then
			return
		end
		local clean = PledgeService.clean(choices)
		if clean == nil then
			return
		end
		local count = 0
		for _, list in clean do
			count += #list
		end
		ProfileService.update(player, function(profile)
			profile.pledge = clean
			ProfileSchema.addJournalEntry(profile, {
				id = "pledge:night_sky",
				kind = "pledge",
				key = "night_sky",
				at = os.time(),
				data = { count = count },
			})
		end)
		ProfileService.checkpoint(player)
		FixturePuzzleService.notify(player, "notice_pledge_saved")
		MetricsService.log(player, "pledge_made", count)
		for _, callback in listeners do
			task.spawn(callback, player)
		end
	end)
end

return PledgeService
