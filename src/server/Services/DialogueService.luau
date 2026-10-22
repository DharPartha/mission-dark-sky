--!strict
-- DialogueService: sends dialogue line ids to clients (clients look up the text, so it
-- stays localizable) and estimates how long a sequence takes so the quest can wait for it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local BubbleTheme = require(ConfigFolder:WaitForChild("BubbleTheme"))
local Text = require(SharedFolder:WaitForChild("Text"))

local DialogueService = {}

local dialogueEvent: RemoteEvent

function DialogueService.init(remote: RemoteEvent)
	dialogueEvent = remote
end

-- Matches the client's typewriter + hold timing, so the quest moves on about when
-- the last bubble closes. Tapping to skip only makes the client finish sooner.
function DialogueService.estimateSeconds(lineIds: { string }): number
	local total = 0
	for _, lineId in lineIds do
		local line = Text.line(lineId)
		local length = if line then utf8.len(line.text) or #line.text else 0
		total += length / BubbleTheme.CharactersPerSecond
			+ BubbleTheme.HoldSecondsBase
			+ length * BubbleTheme.HoldSecondsPerCharacter
	end
	return total
end

-- Plays lines for the given players (everyone when nil). Returns the estimated duration.
function DialogueService.play(lineIds: { string }, players: { Player }?): number
	if players then
		for _, player in players do
			dialogueEvent:FireClient(player, lineIds)
		end
	else
		dialogueEvent:FireAllClients(lineIds)
	end
	return DialogueService.estimateSeconds(lineIds)
end

function DialogueService.playSequence(sequenceId: string, players: { Player }?): number
	local lineIds = (DialogueConfig.Sequences :: any)[sequenceId]
	if lineIds == nil then
		warn(string.format("[DarkSky] Dialogue sequence '%s' does not exist", sequenceId))
		return 0
	end
	return DialogueService.play(lineIds, players)
end

return DialogueService
