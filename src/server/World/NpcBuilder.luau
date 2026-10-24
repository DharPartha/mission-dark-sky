--!strict
-- NpcBuilder: the three friends (Aadi, Aditya, Adrika) as NPC companions with Talk
-- prompts, and moving them between story stations (WorldConfig.CompanionStations).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Config")
local DialogueConfig = require(ConfigFolder:WaitForChild("DialogueConfig"))
local Tuning = require(ConfigFolder:WaitForChild("Tuning"))
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local Text = require(ReplicatedStorage:WaitForChild("DarkSky"):WaitForChild("Shared"):WaitForChild("Text"))

local Parts = require(script.Parent:WaitForChild("Parts"))

local NpcBuilder = {}

NpcBuilder.Tag = "DarkSkyNpc"

-- Shirt colors make the three friends easy to tell apart (with names over their heads).
local FRIENDS = {
	{ name = "Aadi", shirt = Color3.fromRGB(214, 120, 52) },
	{ name = "Aditya", shirt = Color3.fromRGB(64, 140, 196) },
	{ name = "Adrika", shirt = Color3.fromRGB(150, 92, 190) },
}

export type Friends = { models: { [string]: Model }, prompts: { [string]: ProximityPrompt } }

local function buildFriend(name: string, shirt: Color3, parent: Instance): (Model, ProximityPrompt)
	local model: Model? = nil
	-- Yields while avatar assets load; falls back to a block figure if it fails.
	local ok, result = pcall(function()
		local description = Instance.new("HumanoidDescription")
		description.TorsoColor = shirt
		description.LeftArmColor = shirt
		description.RightArmColor = shirt
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		model = result
	else
		local fallback = Instance.new("Model")
		local body = Parts.makePart({ name = "HumanoidRootPart", size = Vector3.new(2, 3, 1), cframe = CFrame.new(0, 2.5, 0), color = shirt, parent = fallback })
		Parts.makePart({ name = "Head", size = Vector3.new(1.4, 1.4, 1.4), cframe = CFrame.new(0, 4.8, 0), color = Color3.fromRGB(196, 150, 110), parent = fallback })
		Instance.new("Humanoid").Parent = fallback
		fallback.PrimaryPart = body
		model = fallback
	end

	local npc = model :: Model
	npc.Name = name
	npc.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	npc:SetAttribute("Speaker", name)
	CollectionService:AddTag(npc, NpcBuilder.Tag)
	for _, descendant in npc:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	local displayName = (DialogueConfig.Speakers :: any)[name].displayName
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = displayName
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		humanoid.NameDisplayDistance = 60
	end
	npc.Parent = parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = Text.get("prompt_talk")
	prompt.ObjectText = displayName
	prompt.MaxActivationDistance = Tuning.Interact.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt:SetAttribute("Speaker", name)
	prompt.Parent = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	return npc, prompt
end

-- Moves the friends to a story station, facing its lookAt point.
function NpcBuilder.placeAt(friends: Friends, stationId: string)
	local station = (WorldConfig.CompanionStations :: any)[stationId]
	if station == nil then
		return
	end
	for name, model in friends.models do
		local position: Vector3? = station[name]
		if position then
			local pivot = position + Vector3.new(0, 3, 0)
			local lookAt: Vector3 = station.lookAt
			model:PivotTo(CFrame.lookAt(pivot, Vector3.new(lookAt.X, pivot.Y, lookAt.Z)))
		end
	end
end

function NpcBuilder.build(parent: Instance, startStation: string): Friends
	local folder = Parts.makeFolder("Friends", parent)
	local friends: Friends = { models = {}, prompts = {} }
	for _, friend in FRIENDS do
		local model, prompt = buildFriend(friend.name, friend.shirt, folder)
		friends.models[friend.name] = model
		friends.prompts[friend.name] = prompt
	end
	NpcBuilder.placeAt(friends, startStation)
	return friends
end

return NpcBuilder
