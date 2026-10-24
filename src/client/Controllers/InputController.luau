--!strict
-- InputController: shortcuts and gamepad menu navigation.
--   Keyboard: L Lux Lens, J Star Journal, G hint (E interact, F talk, R ride, H high-five)
--   Gamepad:  D-pad left Lux Lens, D-pad down Star Journal (Select stays Roblox's own
--             menu-navigation button); menus open with the first
--             button selected so they can be used without a mouse or touch.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local ScreenManager = require(script.Parent:WaitForChild("ScreenManager"))

local InputController = {}

local function usingGamepad(): boolean
	local last = UserInputService:GetLastInputType()
	return last.Name:sub(1, 7) == "Gamepad"
end

-- Selects the first visible button in a panel so the gamepad can navigate it.
function InputController.focusPanel(panel: GuiObject)
	if not usingGamepad() then
		return
	end
	local best: GuiObject? = nil
	local bestY = math.huge
	for _, child in panel:GetDescendants() do
		if child:IsA("GuiButton") and child.Visible and child.Selectable and child.AbsolutePosition.Y < bestY then
			best = child
			bestY = child.AbsolutePosition.Y
		end
	end
	if best then
		GuiService.SelectedObject = best
	end
end

function InputController.init(actions: { toggleLens: () -> (), requestHint: () -> () })
	ContextActionService:BindAction("DarkSkyLens", function(_, state)
		if state == Enum.UserInputState.Begin then
			actions.toggleLens()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.L, Enum.KeyCode.DPadLeft)

	ContextActionService:BindAction("DarkSkyJournal", function(_, state)
		if state == Enum.UserInputState.Begin then
			ScreenManager.toggle("Journal")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.J, Enum.KeyCode.DPadDown)

	ContextActionService:BindAction("DarkSkyHint", function(_, state)
		if state == Enum.UserInputState.Begin then
			actions.requestHint()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.G)

	ScreenManager.onOpened(InputController.focusPanel)
	ScreenManager.onClosed(function()
		if GuiService.SelectedObject then
			GuiService.SelectedObject = nil
		end
	end)
end

return InputController
