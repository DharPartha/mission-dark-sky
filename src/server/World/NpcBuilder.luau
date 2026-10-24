--!strict
-- NpcBuilder: the three friends (Aadi, Aditya, Adrika) as NPC companions with Talk
-- prompts, and moving them between story stations (WorldConfig.CompanionStations).

local CollectionService = game:GetService("CollectionService")
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

local SKIN = Color3.fromRGB(196, 150, 110)
local PANTS = Color3.fromRGB(40, 44, 60)

-- Builds a simple block figure from plain parts. No avatar download, so the friends always
-- appear (default avatar meshes failed to load in unpublished Studio files). Placeholder
-- art until the owner supplies character models. Built around the origin; placeAt moves it.
local function blockFigure(shirt: Color3): Model
	local model = Instance.new("Model")
	-- Invisible root at the usual character height, used for pivoting and the Talk prompt.
	local root = Parts.makePart({ name = "HumanoidRootPart", size = Vector3.new(2, 2, 1), cframe = CFrame.new(0, 0, 0), color = shirt, transparency = 1, canCollide = false, parent = model })
	Parts.makePart({ name = "Torso", size = Vector3.new(2, 2, 1), cframe = CFrame.new(0, 0, 0), color = shirt, parent = model })
	Parts.makePart({ name = "LeftArm", size = Vector3.new(1, 2, 1), cframe = CFrame.new(-1.5, 0, 0), color = shirt, parent = model })
	Parts.makePart({ name = "RightArm", size = Vector3.new(1, 2, 1), cframe = CFrame.new(1.5, 0, 0), color = shirt, parent = model })
	Parts.makePart({ name = "LeftLeg", size = Vector3.new(1, 2, 1), cframe = CFrame.new(-0.5, -2, 0), color = PANTS, parent = model })
	Parts.makePart({ name = "RightLeg", size = Vector3.new(1, 2, 1), cframe = CFrame.new(0.5, -2, 0), color = PANTS, parent = model })
	local head = Parts.makePart({ name = "Head", size = Vector3.new(1.2, 1.2, 1.2), cframe = CFrame.new(0, 1.6, 0), color = SKIN, parent = model })
	-- Built-in Studio face texture (a local file, nothing to download).
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head
	-- A small warm light so the friends are easy to spot at night (soft, no shadows).
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 214, 160)
	glow.Range = 9
	glow.Brightness = 0.7
	glow.Shadows = false
	glow.Parent = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

local function buildFriend(name: string, shirt: Color3, parent: Instance): (Model, ProximityPrompt)
	local npc = blockFigure(shirt)
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
