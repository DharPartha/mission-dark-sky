--!strict
-- QualityController: Low / Medium / High effect levels for phones and older PCs.
-- "Auto" follows the player's Roblox graphics quality setting.
-- Effects read QualityController.effectScale() and react to QualityController.changed.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Shadow-casting light budget per tier: only the nearest lights cast shadows.
-- (Design target: about 12 shadow-casting lights in view at High.)
local SHADOW_BUDGET = { Low = 0, Mid = 6, High = 12 }
local BUDGET_REFRESH_SECONDS = 1

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
	changedEvent:Fire(tier)
end

local spotLights: { SpotLight } = {}

-- Shadows are the most expensive lighting effect, so only the nearest lights within the
-- tier's budget cast them. Runs locally; other players' settings are unaffected.
local function applyShadowBudget()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local budget = SHADOW_BUDGET[QualityController.tier()] or 0
	local here = camera.CFrame.Position
	local ranked = {}
	for index = #spotLights, 1, -1 do
		local light = spotLights[index]
		local part = light.Parent
		if part == nil or not part:IsA("BasePart") then
			table.remove(spotLights, index)
		else
			table.insert(ranked, { light = light, distance = (part.Position - here).Magnitude })
		end
	end
	table.sort(ranked, function(a, b)
		return a.distance < b.distance
	end)
	for rank, entry in ranked do
		entry.light.Shadows = rank <= budget
	end
end

function QualityController.shadowBudget(): number
	return SHADOW_BUDGET[QualityController.tier()] or 0
end

function QualityController.cycle()
	local index = table.find(CHOICES, choice) or 1
	choice = CHOICES[(index % #CHOICES) + 1]
	apply()
	applyShadowBudget()
end

-- Restores a saved choice (from the player's profile).
function QualityController.setChoice(newChoice: string)
	if table.find(CHOICES, newChoice :: any) and newChoice ~= choice then
		choice = newChoice :: Choice
		apply()
		applyShadowBudget()
	end
end

function QualityController.init()
	apply()
	-- Never block UI startup waiting for the world.
	task.spawn(function()
		local world = Workspace:WaitForChild("DarkSkyWorld", 30)
		if world == nil then
			return
		end
		for _, light in world:GetDescendants() do
			if light:IsA("SpotLight") then
				table.insert(spotLights, light)
			end
		end
		world.DescendantAdded:Connect(function(light)
			if light:IsA("SpotLight") then
				table.insert(spotLights, light)
			end
		end)
	end)
	task.spawn(function()
		while true do
			applyShadowBudget()
			task.wait(BUDGET_REFRESH_SECONDS)
		end
	end)
end

return QualityController
