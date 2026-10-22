--!strict
-- GameStateService: the one authoritative copy of fixture states, zone scores, evidence,
-- Doubt Tokens, and quest phase. Clients only read it, through attributes on
-- ReplicatedStorage.DarkSky.State (attributes replicate and late joiners get them too).
--
-- State layout:
--   State                 QuestPhase, ObjectiveKey, ObjectiveArg, DoubtTokens, RestoredRealms,
--                         <Zone>Score/Glare/Uplight/Blue/Safe, <Zone>Base* (before snapshot),
--                         Vote* (Moon tip vote)
--   State/Fixtures/<id>   On, Brightness, Shielded, Aim, ColorTempK, Schedule, Questioned,
--                         Glare, Uplight, BlueLight
--   State/Evidence        one true attribute per evidence key found

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = ReplicatedStorage:WaitForChild("DarkSky")
local ConfigFolder = Root:WaitForChild("Config")
local SharedFolder = Root:WaitForChild("Shared")
local FixtureConfig = require(ConfigFolder:WaitForChild("FixtureConfig"))
local Types = require(SharedFolder:WaitForChild("Types"))
local DarknessMath = require(SharedFolder:WaitForChild("DarknessMath"))
local FixtureRules = require(SharedFolder:WaitForChild("FixtureRules"))
local Net = require(SharedFolder:WaitForChild("Net"))

local GameStateService = {}

type ZoneChangedCallback = (zoneId: string, summary: Types.ZoneSummary) -> ()
type FixtureChangedCallback = (fixtureId: string, state: Types.FixtureState) -> ()

local stateFolder: Folder
local fixtureFolders: { [string]: Folder } = {}
local evidenceFolder: Folder
local fixtureStates: { [string]: Types.FixtureState } = {}
local fixtureDefs: { [string]: Types.FixtureDefinition } = {}
local fixtureZone: { [string]: string } = {}
local journal: { { [string]: any } } = {}
local zoneListeners: { ZoneChangedCallback } = {}
local fixtureListeners: { FixtureChangedCallback } = {}

local function zoneDef(zoneId: string): Types.ZoneDefinition
	return (FixtureConfig.Zones :: any)[zoneId]
end

local function writeFixtureAttributes(id: string)
	local folder = fixtureFolders[id]
	local state = fixtureStates[id]
	local readings = DarknessMath.readFixture(fixtureDefs[id], state)
	folder:SetAttribute("On", state.on)
	folder:SetAttribute("Brightness", state.brightness)
	folder:SetAttribute("Shielded", state.shielded)
	folder:SetAttribute("Aim", state.aim)
	folder:SetAttribute("ColorTempK", state.colorTempK)
	folder:SetAttribute("Schedule", state.schedule)
	folder:SetAttribute("Glare", readings.glare)
	folder:SetAttribute("Uplight", readings.uplight)
	folder:SetAttribute("BlueLight", readings.blueLight)
end

local function zoneStates(zoneId: string): { [string]: Types.FixtureState }
	local states = {}
	for _, def in zoneDef(zoneId).fixtures do
		states[def.id] = fixtureStates[def.id]
	end
	return states
end

local function recomputeZone(zoneId: string): Types.ZoneSummary
	local summary = DarknessMath.summarizeZone(zoneDef(zoneId), zoneStates(zoneId))
	stateFolder:SetAttribute(zoneId .. "Score", summary.score)
	stateFolder:SetAttribute(zoneId .. "Glare", summary.glare)
	stateFolder:SetAttribute(zoneId .. "Uplight", summary.uplight)
	stateFolder:SetAttribute(zoneId .. "Blue", summary.blueLight)
	stateFolder:SetAttribute(zoneId .. "Safe", summary.safePathLit)
	for _, callback in zoneListeners do
		task.spawn(callback, zoneId, summary)
	end
	return summary
end

function GameStateService.init()
	local existing = Root:FindFirstChild(Net.StateFolder)
	if existing then
		existing:Destroy()
	end
	stateFolder = Instance.new("Folder")
	stateFolder.Name = Net.StateFolder

	local fixturesRoot = Instance.new("Folder")
	fixturesRoot.Name = "Fixtures"
	fixturesRoot.Parent = stateFolder

	evidenceFolder = Instance.new("Folder")
	evidenceFolder.Name = "Evidence"
	evidenceFolder.Parent = stateFolder

	for zoneId, zone in FixtureConfig.Zones do
		for _, def in zone.fixtures do
			local typedDef = def :: any
			fixtureDefs[def.id] = typedDef
			fixtureZone[def.id] = zoneId
			fixtureStates[def.id] = FixtureRules.copyState(typedDef.initial)
			local folder = Instance.new("Folder")
			folder.Name = def.id
			folder:SetAttribute("Questioned", false)
			folder.Parent = fixturesRoot
			fixtureFolders[def.id] = folder
			writeFixtureAttributes(def.id)
		end
		stateFolder:SetAttribute(zoneId .. "Threshold", zone.restoreThreshold)
	end

	stateFolder:SetAttribute("DoubtTokens", 0)
	stateFolder:SetAttribute("RestoredRealms", 0)
	stateFolder:SetAttribute("QuestPhase", "Intro")
	stateFolder:SetAttribute("ObjectiveKey", "objective_intro")
	stateFolder.Parent = Root

	for zoneId in FixtureConfig.Zones do
		recomputeZone(zoneId)
	end
end

function GameStateService.getStateFolder(): Folder
	return stateFolder
end

function GameStateService.getDefinition(fixtureId: string): Types.FixtureDefinition?
	return fixtureDefs[fixtureId]
end

function GameStateService.getFixtureState(fixtureId: string): Types.FixtureState?
	local state = fixtureStates[fixtureId]
	return if state then FixtureRules.copyState(state) else nil
end

function GameStateService.getZoneStates(zoneId: string): { [string]: Types.FixtureState }
	return zoneStates(zoneId)
end

function GameStateService.getZoneSummary(zoneId: string): Types.ZoneSummary
	return DarknessMath.summarizeZone(zoneDef(zoneId), zoneStates(zoneId))
end

function GameStateService.setFixtureState(fixtureId: string, state: Types.FixtureState)
	fixtureStates[fixtureId] = FixtureRules.copyState(state)
	writeFixtureAttributes(fixtureId)
	for _, callback in fixtureListeners do
		task.spawn(callback, fixtureId, fixtureStates[fixtureId])
	end
	recomputeZone(fixtureZone[fixtureId])
end

function GameStateService.markQuestioned(fixtureId: string)
	local folder = fixtureFolders[fixtureId]
	if folder then
		folder:SetAttribute("Questioned", true)
	end
end

-- Saves the current zone numbers as the "before" side of the before/after panel.
function GameStateService.captureBaseline(zoneId: string)
	local summary = GameStateService.getZoneSummary(zoneId)
	stateFolder:SetAttribute(zoneId .. "BaseScore", summary.score)
	stateFolder:SetAttribute(zoneId .. "BaseGlare", summary.glare)
	stateFolder:SetAttribute(zoneId .. "BaseUplight", summary.uplight)
	stateFolder:SetAttribute(zoneId .. "BaseBlue", summary.blueLight)
	stateFolder:SetAttribute(zoneId .. "BaseSafe", summary.safePathLit)
end

-- Returns true only the first time a key is found.
function GameStateService.addEvidence(key: string): boolean
	if evidenceFolder:GetAttribute(key) then
		return false
	end
	evidenceFolder:SetAttribute(key, true)
	return true
end

function GameStateService.hasEvidence(key: string): boolean
	return evidenceFolder:GetAttribute(key) == true
end

function GameStateService.addDoubtToken()
	stateFolder:SetAttribute("DoubtTokens", (stateFolder:GetAttribute("DoubtTokens") or 0) + 1)
end

-- Star Journal UI arrives in Milestone 3; entries are recorded now so nothing is lost.
function GameStateService.addJournalEntry(entry: { [string]: any })
	table.insert(journal, entry)
	stateFolder:SetAttribute("JournalCount", #journal)
end

function GameStateService.setPhase(phase: Types.QuestPhase, objectiveKey: string, objectiveArg: (string | number)?)
	stateFolder:SetAttribute("QuestPhase", phase)
	stateFolder:SetAttribute("ObjectiveKey", objectiveKey)
	stateFolder:SetAttribute("ObjectiveArg", objectiveArg)
end

function GameStateService.getPhase(): Types.QuestPhase
	return stateFolder:GetAttribute("QuestPhase") :: any
end

function GameStateService.setAttribute(name: string, value: any)
	stateFolder:SetAttribute(name, value)
end

function GameStateService.getAttribute(name: string): any
	return stateFolder:GetAttribute(name)
end

-- Test reset: fixtures back to their polluted start, evidence and tokens cleared.
function GameStateService.resetAll()
	for id, def in fixtureDefs do
		fixtureStates[id] = FixtureRules.copyState(def.initial)
		fixtureFolders[id]:SetAttribute("Questioned", false)
		writeFixtureAttributes(id)
		for _, callback in fixtureListeners do
			task.spawn(callback, id, fixtureStates[id])
		end
	end
	for key in evidenceFolder:GetAttributes() do
		evidenceFolder:SetAttribute(key, nil)
	end
	table.clear(journal)
	stateFolder:SetAttribute("JournalCount", 0)
	stateFolder:SetAttribute("DoubtTokens", 0)
	stateFolder:SetAttribute("RestoredRealms", 0)
	for zoneId in FixtureConfig.Zones do
		recomputeZone(zoneId)
	end
end

function GameStateService.onZoneChanged(callback: ZoneChangedCallback)
	table.insert(zoneListeners, callback)
end

function GameStateService.onFixtureChanged(callback: FixtureChangedCallback)
	table.insert(fixtureListeners, callback)
end

return GameStateService
