--!strict
-- BubbleTheme: look and timing of comic dialogue bubbles.

local BubbleTheme = {
	Styles = {
		speech = {
			background = Color3.fromRGB(250, 248, 240),
			text = Color3.fromRGB(24, 26, 36),
			stroke = Color3.fromRGB(24, 26, 36),
			strokeThickness = 2,
			italic = false,
		},
		shout = {
			background = Color3.fromRGB(255, 226, 168),
			text = Color3.fromRGB(70, 18, 10),
			stroke = Color3.fromRGB(150, 44, 20),
			strokeThickness = 4,
			italic = false,
		},
		thought = {
			background = Color3.fromRGB(226, 232, 250),
			text = Color3.fromRGB(40, 44, 70),
			stroke = Color3.fromRGB(120, 130, 170),
			strokeThickness = 2,
			italic = true,
		},
		narration = {
			background = Color3.fromRGB(18, 22, 40),
			text = Color3.fromRGB(236, 240, 255),
			stroke = Color3.fromRGB(120, 140, 210),
			strokeThickness = 2,
			italic = false,
		},
	},
	-- Typewriter speed. Tapping a bubble completes it instantly.
	CharactersPerSecond = 45,
	-- Auto-advance waits this long after a line finishes typing, plus a little per character.
	HoldSecondsBase = 1.6,
	HoldSecondsPerCharacter = 0.035,
	-- Most bubbles shown on screen at once; older ones fade out.
	MaxVisible = 3,
	-- Base text size; the Large Text setting multiplies it.
	TextSize = 20,
}

return BubbleTheme
