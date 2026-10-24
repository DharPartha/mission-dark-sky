--!strict
-- GlareService: the only "penalty" in the game. A glared player walks slower and their
-- screen washes out for a few seconds (one soft fade, no flashing, no damage).
-- Recovery: wait it out, or a teammate walks up and gives a High-five to clear it early.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))

local FixturePuzzleService = require(script.Parent:WaitForChild("FixturePuzzleService"))

local GlareService = {}

local HIGH_FIVE_DISTANCE = 10

local glareEvent: RemoteEvent
-- Newest glare per player; only that one may end the effect.
local tokens: { [Player]: number } = {}
local prompts: { [Player]: ProximityPrompt } = {}

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	return humanoid, if rootPart and rootPart:IsA("BasePart") then rootPart else nil
end

function GlareService.clear(player: Player)
	tokens[player] = nil
	local prompt = prompts[player]
	if prompt then
		prompt:Destroy()
		prompts[player] = nil
	end
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Parent and player:GetAttribute("Riding") ~= true then
		humanoid.WalkSpeed = Tuning.Glare.NormalWalkSpeed
	end
	if player.Parent == Players then
		glareEvent:FireClient(player, "clear", 0)
	end
end

function GlareService.isGlared(player: Player): boolean
	return tokens[player] ~= nil
end

function GlareService.apply(player: Player)
	local humanoid, rootPart = humanoidOf(player)
	if humanoid == nil or rootPart == nil or humanoid.Health <= 0 then
		return
	end
	local token = (tokens[player] or 0) + 1
	tokens[player] = token
	humanoid.WalkSpeed = Tuning.Glare.SlowWalkSpeed
	glareEvent:FireClient(player, "hit", Tuning.Glare.DurationSeconds)
	FixturePuzzleService.notify(player, "notice_glare_hit")

	if prompts[player] == nil then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HighFivePrompt"
		prompt.ActionText = Text.get("prompt_highfive")
		prompt.ObjectText = Text.get("prompt_highfive_object")
		prompt.MaxActivationDistance = HIGH_FIVE_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.KeyboardKeyCode = Enum.KeyCode.H
		prompt.GamepadKeyCode = Enum.KeyCode.DPadRight
		prompt:SetAttribute("TargetUserId", player.UserId)
		prompt.Triggered:Connect(function(helper: Player)
			-- You cannot high-five yourself; a teammate has to come over.
			if helper ~= player and tokens[player] ~= nil then
				GlareService.clear(player)
				FixturePuzzleService.notify(player, "notice_highfived")
			end
		end)
		prompt.Parent = rootPart
		prompts[player] = prompt
	end

	task.delay(Tuning.Glare.DurationSeconds, function()
		if tokens[player] == token then
			GlareService.clear(player)
		end
	end)
end

function GlareService.clearAll()
	for player in tokens do
		GlareService.clear(player)
	end
end

function GlareService.init(remotes: { [string]: RemoteEvent })
	glareEvent = remotes.GlareEvent
	Players.PlayerRemoving:Connect(function(player)
		tokens[player] = nil
		prompts[player] = nil
	end)
	-- A respawned character starts clear (the old prompt went with the old character).
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			tokens[player] = nil
			prompts[player] = nil
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return GlareService
