--!strict
-- ScreenManager: keeps at most one full panel (Journal, Compare, Settings...) open at a
-- time, so panels never stack on small phone screens. The gamepad B button closes it.

local UserInputService = game:GetService("UserInputService")

local ScreenManager = {}

local panels: { [string]: GuiObject } = {}
local openName: string? = nil
local openedListeners: { [string]: () -> () } = {}

function ScreenManager.register(name: string, panel: GuiObject, onOpened: (() -> ())?)
	panels[name] = panel
	panel.Visible = false
	if onOpened then
		openedListeners[name] = onOpened
	end
end

function ScreenManager.close()
	if openName and panels[openName] then
		panels[openName].Visible = false
	end
	openName = nil
end

function ScreenManager.open(name: string)
	local panel = panels[name]
	if panel == nil then
		return
	end
	ScreenManager.close()
	openName = name
	panel.Visible = true
	local listener = openedListeners[name]
	if listener then
		listener()
	end
end

function ScreenManager.toggle(name: string)
	if openName == name then
		ScreenManager.close()
	else
		ScreenManager.open(name)
	end
end

function ScreenManager.isOpen(name: string): boolean
	return openName == name
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.ButtonB and openName then
		ScreenManager.close()
	end
end)

return ScreenManager
