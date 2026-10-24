--!strict
-- SettingsSync: accessibility and graphics choices follow the player between sessions.
-- On join it applies the saved values from the player's profile; afterwards it sends
-- changes (debounced) for the server to validate and save. Works without saving too.

local Players = game:GetService("Players")

local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))
local QualityController = require(script.Parent:WaitForChild("QualityController"))

local SettingsSync = {}

local SEND_DELAY_SECONDS = 1.5
local BOOL_SETTINGS = { "reducedMotion", "largeText", "highContrast" }

function SettingsSync.init(remote: RemoteEvent)
	local pendingToken = 0
	local applying = false

	local function send()
		if applying then
			return
		end
		pendingToken += 1
		local token = pendingToken
		task.delay(SEND_DELAY_SECONDS, function()
			if token ~= pendingToken then
				return
			end
			local values: { [string]: any } = { quality = QualityController.choice() }
			for _, name in BOOL_SETTINGS do
				values[name] = ClientSettings.get(name :: any)
			end
			remote:FireServer(values)
		end)
	end

	task.spawn(function()
		local folder = Players.LocalPlayer:WaitForChild("DarkSkyProfile")
		-- Wait for the save to finish loading before applying it.
		while folder:GetAttribute("SaveStatus") == "loading" do
			folder.AttributeChanged:Wait()
		end
		applying = true
		for _, name in BOOL_SETTINGS do
			local saved = folder:GetAttribute("Setting_" .. name)
			if typeof(saved) == "boolean" then
				ClientSettings.set(name :: any, saved)
			end
		end
		local quality = folder:GetAttribute("Setting_quality")
		if typeof(quality) == "string" then
			QualityController.setChoice(quality)
		end
		applying = false
		ClientSettings.changed:Connect(send)
		QualityController.changed:Connect(send)
	end)
end

return SettingsSync
