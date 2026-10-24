--!strict
-- MoonTipService: the team "Doubt it!" vote on one Moon claim.
-- Everyone in the server votes with preset buttons (works with chat off; solo = team of 1).
-- Resolves when all present players voted or the timer ends. Majority decides; a tie
-- lets the Moon push her answer (no token). Rewards are applied by the caller.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Tuning = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config"):WaitForChild("Tuning"))
local PartyRules = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("PartyRules"))
local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))

local MoonTipService = {}

export type Outcome = {
	tip: { [string]: any },
	choice: "doubt" | "agree" | "tie",
	correct: boolean,
	sequence: string,
}

local activeTip: { [string]: any }? = nil
local onResolved: ((Outcome) -> ())? = nil
local votes: { [Player]: string } = {}
local round = 0

local function resolve()
	local tip = activeTip
	local callback = onResolved
	if tip == nil then
		return
	end
	activeTip = nil
	onResolved = nil

	local doubt, agree = 0, 0
	for player, choice in votes do
		if player.Parent == Players then
			if choice == "doubt" then
				doubt += 1
			else
				agree += 1
			end
		end
	end
	table.clear(votes)
	WorldStateService.setAttribute("VoteTipId", nil)

	local outcome: Outcome
	if doubt == agree then
		outcome = { tip = tip, choice = "tie", correct = false, sequence = tip.onTie }
	elseif doubt > agree then
		outcome = { tip = tip, choice = "doubt", correct = tip.isMisleading, sequence = tip.onDoubt }
	else
		outcome = { tip = tip, choice = "agree", correct = not tip.isMisleading, sequence = tip.onAgree }
	end
	if callback then
		callback(outcome)
	end
end

local function updateCount()
	if activeTip == nil then
		return
	end
	local cast = 0
	for player in votes do
		if player.Parent == Players then
			cast += 1
		end
	end
	local needed = #Players:GetPlayers()
	WorldStateService.setAttribute("VotesCast", cast)
	WorldStateService.setAttribute("VotersNeeded", needed)
	if cast >= needed then
		resolve()
	end
end

function MoonTipService.init(remotes: { [string]: RemoteEvent })
	RemoteGuard.connect(remotes.MoonVote, "MoonVote", function(player: Player, choice: any)
		if activeTip == nil or (choice ~= "doubt" and choice ~= "agree") then
			return
		end
		-- Players may change their vote until it resolves.
		votes[player] = choice
		updateCount()
	end)
	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		task.defer(updateCount)
	end)
end

function MoonTipService.start(tip: { [string]: any }, callback: (Outcome) -> ())
	round += 1
	local myRound = round
	activeTip = tip
	onResolved = callback
	table.clear(votes)
	WorldStateService.setAttribute("VoteTipId", tip.id)
	local seconds = PartyRules.voteSeconds(Tuning.Moon.VoteTimeoutSeconds, #Players:GetPlayers())
	WorldStateService.setAttribute("VoteDeadline", Workspace:GetServerTimeNow() + seconds)
	updateCount()
	task.delay(seconds, function()
		if round == myRound then
			resolve()
		end
	end)
end

function MoonTipService.cancel()
	round += 1
	activeTip = nil
	onResolved = nil
	table.clear(votes)
	WorldStateService.setAttribute("VoteTipId", nil)
end

return MoonTipService
