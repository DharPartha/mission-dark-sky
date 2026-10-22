--!strict
-- QualityController: Low / Medium / High effect levels for phones and older PCs.
-- "Auto" follows the player's Roblox graphics quality setting.
-- Effects read QualityController.effectScale() and react to QualityController.changed.

local Lighting = game:GetService("Lighting")

local QualityController = {}

export type Tier = "Low" | "Mid" | "High"
export type Choice = "Auto" | Tier

local CHOICES: { Choice } = { "Auto", "Low", "Mid", "High" }
local choice: Choice = "Auto"
local changedEvent = Instance.new("BindableEvent")
QualityController.changed = changedEvent.Event

local function autoTier(): Tier
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	-- SavedQualityLevel 0 = automatic, 1-10 = manual slider.
	if not ok or level == 0 then
		return "Mid"
	elseif level <= 3 then
		return "Low"
	elseif level <= 7 then
		return "Mid"
	end
	return "High"
end

function QualityController.tier(): Tier
	return if choice == "Auto" then autoTier() else choice :: Tier
end

function QualityController.choice(): Choice
	return choice
end

-- Multiplier for particle rates and similar counts.
function QualityController.effectScale(): number
	local tier = QualityController.tier()
	return if tier == "Low" then 0.25 elseif tier == "Mid" then 0.6 else 1
end

local function apply()
	local tier = QualityController.tier()
	local bloom = Lighting:FindFirstChild("DarkSkyBloom")
	if bloom and bloom:IsA("BloomEffect") then
		bloom.Enabled = tier ~= "Low"
	end
	-- Shadows from fixture spotlights are the most expensive effect; only High keeps them all.
	local world = workspace:FindFirstChild("DarkSkyWorld")
	if world then
		for _, light in world:GetDescendants() do
			if light:IsA("SpotLight") then
				light.Shadows = tier ~= "Low"
			end
		end
	end
	changedEvent:Fire(tier)
end

function QualityController.cycle()
	local index = table.find(CHOICES, choice) or 1
	choice = CHOICES[(index % #CHOICES) + 1]
	apply()
end

function QualityController.init()
	apply()
end

return QualityController
