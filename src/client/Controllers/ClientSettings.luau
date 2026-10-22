--!strict
-- ClientSettings: per-player accessibility settings (this session only; no saving yet).
-- Controllers read values with ClientSettings.get and react through ClientSettings.changed.

local GuiService = game:GetService("GuiService")

local ClientSettings = {}

export type SettingName = "reducedMotion" | "largeText" | "highContrast"

local values: { [string]: boolean } = {
	reducedMotion = false,
	largeText = false,
	highContrast = false,
}

-- Respect the player's Roblox-wide reduced motion setting when the engine exposes it.
local ok, systemReducedMotion = pcall(function()
	return (GuiService :: any).ReducedMotionEnabled
end)
if ok and systemReducedMotion == true then
	values.reducedMotion = true
end

local changedEvent = Instance.new("BindableEvent")
ClientSettings.changed = changedEvent.Event

function ClientSettings.get(name: SettingName): boolean
	return values[name] == true
end

function ClientSettings.set(name: SettingName, value: boolean)
	if values[name] == value then
		return
	end
	values[name] = value
	changedEvent:Fire(name, value)
end

-- Text size multiplier for the Large Text setting.
function ClientSettings.textScale(): number
	return if values.largeText then 1.3 else 1
end

return ClientSettings
