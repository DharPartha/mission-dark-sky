--!strict
-- ScreenManager: keeps at most one full panel (Journal, Compare, Settings...) open at a
-- time, so panels never stack on small phone screens. The gamepad B button closes it.

local UserInputService = game:GetService("UserInputService")

local ScreenManager = {}

local panels: { [string]: GuiObject } = {}
local openName: string? = nil
local openedListeners: { [string]: () -> () } = {}
local anyOpened: { (panel: GuiObject) -> () } = {}
local anyClosed: { () -> () } = {}

-- Called with the panel whenever any panel opens (gamepad focus uses this).
function ScreenManager.onOpened(callback: (panel: GuiObject) -> ())
	table.insert(anyOpened, callback)
end

function ScreenManager.onClosed(callback: () -> ())
	table.insert(anyClosed, callback)
end

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
	for _, callback in anyClosed do
		callback()
	end
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
	for _, callback in anyOpened do
		-- Deferred so the panel's contents exist before focusing a button.
		task.defer(callback, panel)
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
