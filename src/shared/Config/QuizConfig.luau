--!strict
-- QuizConfig: the short knowledge checks (pre-adventure now, post-adventure in Stage F).
-- Preset choices only, no free text. The same questions are used before and after so the
-- change can be compared. Scores are saved per player as a number (0 to #questions).
-- PLACEHOLDER content: the owner must review questions and answers before release.

local QuizConfig = {
	Quizzes = {
		pre = { titleKey = "quiz_pre_title", introKey = "quiz_pre_intro", questionSet = "core" },
	},
	QuestionSets = {
		core = {
			{
				question = { en = "A light shines into a bedroom window all night. What helps most?" },
				choices = {
					{ en = "Shield it and aim it down at the path" },
					{ en = "Make it brighter so it's even" },
					{ en = "Switch every light on the street off" },
				},
				correct = 1,
			},
			{
				question = { en = "Which light should stay on at night?" },
				choices = {
					{ en = "A decorative light pointing at the sky" },
					{ en = "A crosswalk light where people cross" },
					{ en = "A sign light nobody reads after midnight" },
				},
				correct = 2,
			},
			{
				question = { en = "Why can stars be hard to see from a town?" },
				choices = {
					{ en = "Stars are dimmer over towns" },
					{ en = "Light escaping upward makes the sky glow" },
					{ en = "Clouds are always there at night" },
				},
				correct = 2,
			},
		},
	},
}

return QuizConfig
