--!strict
-- QuizService: personal knowledge checks with preset choices (no free text).
-- The server scores answers, saves only the score in the player's profile, and reports
-- an anonymous score event. Each quiz is answered once per player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuizConfig = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config"):WaitForChild("QuizConfig"))

local WorldStateService = require(script.Parent:WaitForChild("WorldStateService"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local MetricsService = require(script.Parent:WaitForChild("MetricsService"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))

local QuizService = {}

local answeredListeners: { (player: Player, quizId: string) -> () } = {}

local function questionsFor(quizId: string): { any }?
	local quiz = (QuizConfig.Quizzes :: any)[quizId]
	return if quiz then (QuizConfig.QuestionSets :: any)[quiz.questionSet] else nil
end

-- Pure scoring: number of correct answers, or nil if the answers are malformed.
function QuizService.score(quizId: string, answers: any): number?
	local questions = questionsFor(quizId)
	if questions == nil or typeof(answers) ~= "table" or #answers ~= #questions then
		return nil
	end
	local correct = 0
	for index, question in questions do
		local answer = answers[index]
		if typeof(answer) ~= "number" or answer ~= math.floor(answer) or answer < 1 or answer > #question.choices then
			return nil
		end
		if answer == question.correct then
			correct += 1
		end
	end
	return correct
end

function QuizService.hasAnswered(player: Player, quizId: string): boolean
	local profile = ProfileService.getProfile(player)
	return profile ~= nil and profile.quiz[quizId] ~= nil
end

-- True when every player here (with a loaded profile) has answered.
function QuizService.everyoneAnswered(quizId: string): boolean
	for _, player in Players:GetPlayers() do
		if ProfileService.getProfile(player) and not QuizService.hasAnswered(player, quizId) then
			return false
		end
	end
	return true
end

function QuizService.setActive(quizId: string?)
	WorldStateService.setAttribute("QuizActive", quizId)
end

function QuizService.onAnswered(callback: (player: Player, quizId: string) -> ())
	table.insert(answeredListeners, callback)
end

function QuizService.init(remotes: { [string]: RemoteEvent })
	RemoteGuard.connect(remotes.QuizSubmit, "QuizSubmit", function(player: Player, quizId: any, answers: any)
		if typeof(quizId) ~= "string" or WorldStateService.getAttribute("QuizActive") ~= quizId then
			return
		end
		if QuizService.hasAnswered(player, quizId) then
			return
		end
		local score = QuizService.score(quizId, answers)
		if score == nil then
			return
		end
		ProfileService.update(player, function(profile)
			profile.quiz[quizId] = score
		end)
		ProfileService.checkpoint(player)
		MetricsService.log(player, "quiz_" .. quizId .. "_score", score)
		-- Learning change for players who took both checks (aggregate only).
		local quiz = (QuizConfig.Quizzes :: any)[quizId]
		local profile = ProfileService.getProfile(player)
		local earlier = if quiz and quiz.compareWith and profile then profile.quiz[quiz.compareWith] else nil
		if earlier ~= nil then
			MetricsService.log(player, "quiz_change", score - earlier)
		end
		for _, callback in answeredListeners do
			task.spawn(callback, player, quizId)
		end
	end)
end

return QuizService
