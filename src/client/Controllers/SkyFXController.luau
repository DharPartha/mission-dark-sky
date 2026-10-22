--!strict
-- SkyFXController: turns the zone's one Darkness score into coordinated local effects:
-- stars, haze and skyglow color, screen tint, bloom, and the firefly wildlife cue.
-- Also shows Leo's roar telegraph and the temporary Glare washout on this player.
-- Effects never flash more than once per event; reduced motion swaps motion for fades.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local FeatureFlags = require(ConfigFolder:WaitForChild("FeatureFlags"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))

local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))
local QualityController = require(script.Parent:WaitForChild("QualityController"))

local SkyFXController = {}

local ZONE_ID = "Leo"

local state: Folder
local displayedScore = 0
local targetScore = 0
local glareWash: ColorCorrectionEffect

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function applyScore(score: number)
	local t = math.clamp(score / 100, 0, 1)
	local sky = Tuning.Sky
	local skyInstance = Lighting:FindFirstChild("DarkSkySky")
	if skyInstance and skyInstance:IsA("Sky") then
		skyInstance.StarCount = math.floor(lerp(sky.StarCountAt0, sky.StarCountAt100, t))
	end
	local atmosphere = Lighting:FindFirstChild("DarkSkyAtmosphere")
	if atmosphere and atmosphere:IsA("Atmosphere") then
		atmosphere.Density = lerp(sky.AtmosphereDensityAt0, sky.AtmosphereDensityAt100, t)
		atmosphere.Haze = lerp(sky.AtmosphereHazeAt0, sky.AtmosphereHazeAt100, t)
		atmosphere.Glare = lerp(sky.AtmosphereGlareAt0, sky.AtmosphereGlareAt100, t)
		atmosphere.Color = sky.AtmosphereColorAt0:Lerp(sky.AtmosphereColorAt100, t)
	end
	local tint = Lighting:FindFirstChild("DarkSkyTint")
	if tint and tint:IsA("ColorCorrectionEffect") then
		tint.TintColor = sky.TintAt0:Lerp(sky.TintAt100, t)
	end
	local bloom = Lighting:FindFirstChild("DarkSkyBloom")
	if bloom and bloom:IsA("BloomEffect") then
		bloom.Intensity = lerp(0.8, 0.25, t)
	end

	-- Fireflies return once the meadow is dark enough (wildlife cue).
	local world = Workspace:FindFirstChild("DarkSkyWorld")
	local field = world and world:FindFirstChild("MeadowFireflies")
	local emitter = field and field:FindFirstChild("Fireflies")
	if emitter and emitter:IsA("ParticleEmitter") then
		local allowed = FeatureFlags.EnableFireflies and not ClientSettings.get("reducedMotion")
		local from = sky.FirefliesFromScore
		local amount = if score >= from then (score - from) / (100 - from) else 0
		emitter.Rate = if allowed then amount * sky.FireflyRateAt100 * QualityController.effectScale() else 0
	end
end

-- Temporary Glare: a soft washout that fades back. One fade per hit, no strobing.
local function showGlareHit(seconds: number)
	glareWash.Brightness = 0.35
	glareWash.Contrast = -0.3
	glareWash.TintColor = Color3.fromRGB(255, 240, 210)
	local fade = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	TweenService:Create(glareWash, fade, {
		Brightness = 0,
		Contrast = 0,
		TintColor = Color3.new(1, 1, 1),
	}):Play()
end

function SkyFXController.init(stateFolder: Folder, glareEvent: RemoteEvent, onTelegraph: (seconds: number) -> ())
	state = stateFolder

	glareWash = Instance.new("ColorCorrectionEffect")
	glareWash.Name = "DarkSkyGlareWash"
	glareWash.Parent = Lighting

	local function onScoreChanged()
		targetScore = state:GetAttribute(ZONE_ID .. "Score") or 0
		if ClientSettings.get("reducedMotion") then
			displayedScore = targetScore
			applyScore(displayedScore)
		end
	end
	state:GetAttributeChangedSignal(ZONE_ID .. "Score"):Connect(onScoreChanged)
	onScoreChanged()
	displayedScore = targetScore
	applyScore(displayedScore)

	-- Ease toward the target score so the sky clears gradually after each fix.
	RunService.RenderStepped:Connect(function(dt)
		if math.abs(displayedScore - targetScore) < 0.05 then
			return
		end
		local step = (100 / Tuning.Sky.BlendSeconds) * dt
		if displayedScore < targetScore then
			displayedScore = math.min(targetScore, displayedScore + step)
		else
			displayedScore = math.max(targetScore, displayedScore - step)
		end
		applyScore(displayedScore)
	end)

	ClientSettings.changed:Connect(function(name: string)
		if name == "reducedMotion" then
			applyScore(displayedScore)
		end
	end)
	QualityController.changed:Connect(function()
		applyScore(displayedScore)
	end)

	glareEvent.OnClientEvent:Connect(function(kind: any, seconds: any)
		local duration = if typeof(seconds) == "number" then seconds else 3
		if kind == "telegraph" then
			onTelegraph(duration)
		elseif kind == "hit" then
			showGlareHit(duration)
		end
	end)
end

return SkyFXController
