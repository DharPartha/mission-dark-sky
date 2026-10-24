--!strict
-- QuizController: the short knowledge check screen. One question at a time with large
-- preset choice buttons (no typing). Shows when the story starts a quiz this player has
-- not answered yet. No right/wrong is shown before the adventure, so it measures, not teaches.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local QuizConfig = require(Root:WaitForChild("Config"):WaitForChild("QuizConfig"))
local Text = require(Root:WaitForChild("Shared"):WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local QuizController = {}

local panel: Frame
local titleLabel: TextLabel
local progressLabel: TextLabel
local questionLabel: TextLabel
local choicesFrame: Frame
local submitRemote: RemoteEvent
local state: Folder

local activeQuiz: string? = nil
local answers: { number } = {}

local function profileFolder(): Instance?
	return Players.LocalPlayer:FindFirstChild("DarkSkyProfile")
end

local function alreadyAnswered(quizId: string): boolean
	local folder = profileFolder()
	return folder ~= nil and folder:GetAttribute("Quiz_" .. quizId) ~= nil
end

local function clearChoices()
	for _, child in choicesFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function showMessage(key: string)
	clearChoices()
	progressLabel.Text = ""
	questionLabel.Text = Text.get(key)
end

local function showQuestion(index: number)
	local quizId = activeQuiz
	if quizId == nil then
		return
	end
	local quiz = (QuizConfig.Quizzes :: any)[quizId]
	local questions = (QuizConfig.QuestionSets :: any)[quiz.questionSet]
	if index > #questions then
		submitRemote:FireServer(quizId, answers)
		showMessage("quiz_thanks")
		task.delay(2.5, function()
			if activeQuiz == quizId then
				panel.Visible = false
			end
		end)
		return
	end
	local question = questions[index]
	progressLabel.Text = Text.get("quiz_progress", index, #questions)
	questionLabel.Text = Text.pick(question.question)
	clearChoices()
	for choiceIndex, choice in question.choices do
		UiKit.button({
			text = Text.pick(choice),
			size = UDim2.new(1, 0, 0, 56),
			layoutOrder = choiceIndex,
			parent = choicesFrame,
			onClick = function()
				answers[index] = choiceIndex
				showQuestion(index + 1)
			end,
		})
	end
end

local function refresh()
	local quizId = state:GetAttribute("QuizActive")
	if typeof(quizId) ~= "string" then
		activeQuiz = nil
		panel.Visible = false
		return
	end
	if activeQuiz == quizId then
		return
	end
	activeQuiz = quizId
	local quiz = (QuizConfig.Quizzes :: any)[quizId]
	if quiz == nil then
		return
	end
	titleLabel.Text = Text.get(quiz.titleKey)
	panel.Visible = true
	if alreadyAnswered(quizId) then
		showMessage("quiz_waiting")
	else
		answers = {}
		questionLabel.Text = Text.get(quiz.introKey)
		task.delay(2, function()
			if activeQuiz == quizId and not alreadyAnswered(quizId) then
				showQuestion(1)
			end
		end)
	end
end

function QuizController.init(gui: ScreenGui, stateFolder: Folder, remote: RemoteEvent)
	state = stateFolder
	submitRemote = remote

	panel = UiKit.panel("Quiz", gui, 0.02)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.48)
	panel.Size = UDim2.fromOffset(500, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.Visible = false
	UiKit.padding(panel, 16)
	UiKit.list(panel, 10)

	titleLabel = UiKit.label({ text = "", textSize = 24, bold = true, autoHeight = true, layoutOrder = 1, parent = panel })
	progressLabel = UiKit.label({ text = "", textSize = 14, color = UiKit.Colors.muted, autoHeight = true, layoutOrder = 2, parent = panel })
	questionLabel = UiKit.label({ text = "", textSize = 20, autoHeight = true, layoutOrder = 3, parent = panel })
	choicesFrame = Instance.new("Frame")
	choicesFrame.BackgroundTransparency = 1
	choicesFrame.Size = UDim2.new(1, 0, 0, 0)
	choicesFrame.AutomaticSize = Enum.AutomaticSize.Y
	choicesFrame.LayoutOrder = 4
	choicesFrame.Parent = panel
	UiKit.list(choicesFrame, 8)

	state:GetAttributeChangedSignal("QuizActive"):Connect(refresh)
	refresh()
end

return QuizController
