--!strict
-- PhaseMarkerController: during the Moon finale, a floating marker sits above every light the
-- current phase still needs, with a short "what to do" label. The server decides which lights
-- (State.PhaseTargets) and the goal (State.PhaseGoal); this only draws them.
-- Why: the sky beams are small ground lights, and players got stuck trying to switch off the
-- safety lights instead (which is refused). The spec says never hard-lock on a subtle clue.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local FixtureConfig = require(Root:WaitForChild("Config"):WaitForChild("FixtureConfig"))
local Text = require(Root:WaitForChild("Shared"):WaitForChild("Text"))

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local PhaseMarkerController = {}

local MARKER_HEIGHT = 5

local definitions: { [string]: any } = {}
for _, zone in FixtureConfig.Zones do
	for _, def in zone.fixtures do
		definitions[def.id] = def
	end
end

local folder: Folder
local markers: { [string]: Part } = {}

local function clear()
	for _, marker in markers do
		marker:Destroy()
	end
	table.clear(markers)
end

local function makeMarker(fixtureId: string, label: string): Part?
	local def = definitions[fixtureId]
	if def == nil then
		return nil
	end
	local anchor = Instance.new("Part")
	anchor.Name = fixtureId .. "_PhaseMarker"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(def.position + Vector3.new(0, MARKER_HEIGHT, 0))
	anchor.Parent = folder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(230, 64)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 400
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.fromScale(1, 1)
	tag.BackgroundColor3 = UiKit.Colors.buttonPrimary
	tag.BackgroundTransparency = 0.05
	tag.TextColor3 = UiKit.Colors.textDark
	tag.Font = Enum.Font.GothamBold
	tag.TextSize = 16
	tag.TextWrapped = true
	-- An arrow shape plus words, so it never relies on color alone.
	tag.Text = "⬇ " .. Text.get(def.nameKey) .. "\n" .. label
	UiKit.corner(tag, 10)
	tag.Parent = billboard
	return anchor
end

local function refresh(state: Folder)
	clear()
	local targets = state:GetAttribute("PhaseTargets")
	local goal = state:GetAttribute("PhaseGoal")
	if typeof(targets) ~= "string" or typeof(goal) ~= "string" then
		return
	end
	local label = Text.get("phase_marker_" .. goal)
	for fixtureId in string.gmatch(targets, "[^,]+") do
		local marker = makeMarker(fixtureId, label)
		if marker then
			markers[fixtureId] = marker
		end
	end
end

function PhaseMarkerController.init(state: Folder)
	folder = Instance.new("Folder")
	folder.Name = "DarkSkyPhaseMarkers"
	-- Under the camera: local-only and never streamed out.
	folder.Parent = Workspace.CurrentCamera
	state:GetAttributeChangedSignal("PhaseTargets"):Connect(function()
		refresh(state)
	end)
	refresh(state)
end

return PhaseMarkerController
