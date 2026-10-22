--!strict
-- Text: looks up localized strings so scripts never hard-code player-facing text.

local Config = script.Parent.Parent:WaitForChild("Config")
local ExperienceConfig = require(Config:WaitForChild("ExperienceConfig"))
local UIText = require(Config:WaitForChild("UIText"))
local DialogueConfig = require(Config:WaitForChild("DialogueConfig"))

local Text = {}

local currentLocale: string = ExperienceConfig.DefaultLocale

function Text.setLocale(locale: string)
	currentLocale = locale
end

-- Picks the current locale from a { en = "...", es = "..." } table, falling back to the default.
function Text.pick(localized: { [string]: string }?): string
	if localized == nil then
		return ""
	end
	return localized[currentLocale] or localized[ExperienceConfig.DefaultLocale] or ""
end

-- Returns a UIText string. Missing keys show the key in brackets so they are easy to spot.
function Text.get(key: string, ...: any): string
	local entry = (UIText.Strings :: any)[key]
	if entry == nil then
		return "[" .. key .. "]"
	end
	local template = Text.pick(entry)
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, template, ...)
		return if ok then formatted else template
	end
	return template
end

export type DialogueLine = {
	id: string,
	speaker: string,
	displayName: string,
	style: string,
	text: string,
	world: boolean,
}

function Text.line(lineId: string): DialogueLine?
	local line = (DialogueConfig.Lines :: any)[lineId]
	if line == nil then
		return nil
	end
	local speaker = (DialogueConfig.Speakers :: any)[line.speaker] or { displayName = line.speaker, world = false }
	return {
		id = lineId,
		speaker = line.speaker,
		displayName = speaker.displayName,
		style = line.style,
		text = Text.pick(line.text),
		world = speaker.world,
	}
end

return Text
