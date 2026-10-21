local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MissionDarkSky")
local Config = require(Shared:WaitForChild("Config"))
local LightingMath = require(Shared:WaitForChild("LightingMath"))
local Types = require(Shared:WaitForChild("Types"))

type FixtureRuntime = {
	id: string,
	lamp: BasePart,
	light: PointLight,
	enabled: boolean,
	currentLevel: number,
	targetLevel: number,
}

local LightingService = {}

local fixturesById: { [string]: FixtureRuntime } = {}
local statusLabel: TextLabel? = nil
local zoneDisplayName = "Parking Lot"

local function applyLight(runtime: FixtureRuntime)
	local lighting = Config.Lighting
	local current = runtime.currentLevel
	runtime.lamp:SetAttribute("Enabled", runtime.enabled)
	runtime.lamp:SetAttribute("CurrentLevel", current)
	runtime.lamp:SetAttribute("TargetLevel", runtime.targetLevel)

	runtime.light.Enabled = runtime.enabled
	runtime.light.Brightness = current * lighting.PointLightBrightnessAtFull
	runtime.light.Range = lighting.PointLightRangeAtMin
		+ (lighting.PointLightRangeAtFull - lighting.PointLightRangeAtMin) * current

	-- Neon intensity follows current so the lamp head matches the PointLight.
	runtime.lamp.Transparency = 0.05 + (1 - current) * 0.35
end

local function updateStatusLabel()
	if statusLabel == nil then
		return
	end

	local count = 0
	local currentSum = 0
	local targetSum = 0
	for _, runtime in fixturesById do
		count += 1
		currentSum += runtime.currentLevel
		targetSum += runtime.targetLevel
	end
	if count == 0 then
		return
	end

	local currentPct = math.floor((currentSum / count) * 100 + 0.5)
	local targetPct = math.floor((targetSum / count) * 100 + 0.5)
	statusLabel.Text = string.format(
		"%s\ncurrent %d%%  target %d%%",
		zoneDisplayName,
		currentPct,
		targetPct
	)
end

function LightingService.init(lotFolder: Folder)
	table.clear(fixturesById)

	local fixturesFolder = lotFolder:WaitForChild("Fixtures")
	for _, model in fixturesFolder:GetChildren() do
		local lamp = model:FindFirstChild("Lamp")
		if lamp and lamp:IsA("BasePart") then
			local fixtureId = lamp:GetAttribute("FixtureId")
			local light = lamp:FindFirstChildWhichIsA("PointLight")
			if typeof(fixtureId) == "string" and light then
				local runtime: FixtureRuntime = {
					id = fixtureId,
					lamp = lamp,
					light = light,
					enabled = true,
					currentLevel = 0,
					targetLevel = 0,
				}
				fixturesById[fixtureId] = runtime
				applyLight(runtime)
			end
		end
	end

	local debugFolder = lotFolder:FindFirstChild("Debug")
	if debugFolder then
		local statusPart = debugFolder:FindFirstChild("StatusPart")
		if statusPart then
			local gui = statusPart:FindFirstChild("StatusGui")
			if gui then
				local label = gui:FindFirstChild("StatusLabel")
				if label and label:IsA("TextLabel") then
					statusLabel = label
				end
			end
		end
	end

	updateStatusLabel()
end

function LightingService.setEnabled(fixtureId: string, enabled: boolean)
	local runtime = fixturesById[fixtureId]
	if runtime == nil then
		return
	end
	runtime.enabled = enabled
	applyLight(runtime)
end

function LightingService.setTarget(fixtureId: string, level: number)
	local runtime = fixturesById[fixtureId]
	if runtime == nil then
		return
	end
	runtime.targetLevel = LightingMath.clamp(
		level,
		Config.Lighting.MinimumLevel,
		Config.Lighting.MaximumLevel
	)
	runtime.lamp:SetAttribute("TargetLevel", runtime.targetLevel)
	updateStatusLabel()
end

function LightingService.setAllTargets(level: number)
	for fixtureId in fixturesById do
		LightingService.setTarget(fixtureId, level)
	end
end

function LightingService.snapAllToTarget()
	for _, runtime in fixturesById do
		runtime.currentLevel = runtime.targetLevel
		applyLight(runtime)
	end
	updateStatusLabel()
end

function LightingService.getFixtureCount(): number
	local count = 0
	for _ in fixturesById do
		count += 1
	end
	return count
end

function LightingService.getAverageLevel(): number
	local count = 0
	local total = 0
	for _, runtime in fixturesById do
		count += 1
		total += runtime.currentLevel
	end
	return if count > 0 then total / count else 0
end

function LightingService.getState(fixtureId: string): Types.FixtureState?
	local runtime = fixturesById[fixtureId]
	if runtime == nil then
		return nil
	end
	return {
		id = runtime.id,
		enabled = runtime.enabled,
		currentLevel = runtime.currentLevel,
		targetLevel = runtime.targetLevel,
	}
end

function LightingService.step(dt: number)
	local maxDelta = Config.Lighting.RampPerSecond * dt
	for _, runtime in fixturesById do
		local current = runtime.currentLevel
		local target = runtime.targetLevel
		if current < target then
			runtime.currentLevel = math.min(current + maxDelta, target)
		elseif current > target then
			runtime.currentLevel = math.max(current - maxDelta, target)
		end
		applyLight(runtime)
	end
	updateStatusLabel()
end

return LightingService
