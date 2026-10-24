--!strict
-- ReportBuilder: turns a player's own journal, pledge, and three preset choices into the
-- plain-text community proposal (format "DARKSKY-REPORT v1"). Pure: the companion website's
-- parser (site/parser.js) reads exactly this format, and a CLI test checks they agree.
--
-- Contains no names, account details, addresses, or free text. Locations are fictional and
-- every reading is labelled as a simulated game estimate.
--
-- Format:
--   line 1          DARKSKY-REPORT v1
--   header lines    KEY: value   (TITLE, LOCATION, FIXTURE, SOURCE, TOWN)
--   sections        "## NAME", then text lines or "- " bullet lines
--   last line       END OF REPORT

local Config = script.Parent.Parent:WaitForChild("Config")
local ReportConfig = require(Config:WaitForChild("ReportConfig"))
local PledgeConfig = require(Config:WaitForChild("PledgeConfig"))
local MoonTipsConfig = require(Config:WaitForChild("MoonTipsConfig"))
local Text = require(script.Parent:WaitForChild("Text"))

local ReportBuilder = {}

ReportBuilder.Sections = {
	"PROBLEM",
	"EVIDENCE",
	"BEFORE AND AFTER",
	"ALTERNATIVES",
	"RECOMMENDATION",
	"TRADE-OFFS",
	"ESSENTIAL LIGHTING KEPT",
	"NEXT STEPS",
	"REFLECTION",
	"OPTIONAL REAL-WORLD OBSERVATIONS",
}

export type Input = {
	placeId: string,
	recommendationId: string,
	reflectionId: string,
	journal: { { [string]: any } },
	pledge: { [string]: { string } },
}

-- Keeps every value on one line so nothing can break the format.
local function clean(value: string): string
	local oneLine = string.gsub(value, "[\r\n]+", " ")
	return oneLine
end

local function findById(list: { any }, id: string): any
	for _, item in list do
		if item.id == id then
			return item
		end
	end
	return nil
end

-- Places the player can write about: zones they restored, in config order.
function ReportBuilder.availablePlaces(restoredZones: { [string]: boolean }): { string }
	local result = {}
	for _, placeId in { "Home", "Leo", "Orion", "Scorpius", "Cetus" } do
		if restoredZones[placeId] and (ReportConfig.Places :: any)[placeId] then
			table.insert(result, placeId)
		end
	end
	return result
end

-- Returns the report text, or nil if a choice is not valid.
function ReportBuilder.build(input: Input): string?
	local place = (ReportConfig.Places :: any)[input.placeId]
	if place == nil then
		return nil
	end
	local recommendation = findById(place.recommendations, input.recommendationId)
	local reflection = findById(ReportConfig.Reflections, input.reflectionId)
	if recommendation == nil or reflection == nil then
		return nil
	end

	local lines: { string } = {}
	local function add(line: string)
		table.insert(lines, clean(line))
	end
	local function section(name: string)
		add("")
		add("## " .. name)
	end

	add(ReportConfig.FormatHeader)
	add("TITLE: " .. Text.pick(ReportConfig.Title))
	add("LOCATION: " .. Text.pick(place.location))
	add("FIXTURE: " .. Text.pick(place.fixture))
	add("SOURCE: " .. Text.pick(ReportConfig.SourceNote))
	add("TOWN: " .. Text.pick(ReportConfig.TownNote))

	section("PROBLEM")
	add(Text.pick(place.problem))

	-- Evidence: what the team found in the game (simulated), plus this place's scores.
	section("EVIDENCE")
	local before, after = nil, nil
	for _, entry in input.journal do
		if entry.kind == "evidence" then
			local card = (MoonTipsConfig.Evidence :: any)[entry.key]
			if card then
				add("- " .. Text.pick(card.title) .. ": " .. Text.pick(card.text))
			end
		elseif entry.kind == "realm" and entry.key == input.placeId and typeof(entry.data) == "table" then
			before, after = entry.data.before, entry.data.after
		end
	end
	add("- " .. Text.pick(ReportConfig.SourceNote))

	section("BEFORE AND AFTER")
	if typeof(before) == "number" and typeof(after) == "number" then
		add(string.format("- Before: Darkness score %d / 100 (simulated)", before))
		add(string.format("- After: Darkness score %d / 100 (simulated)", after))
	else
		add("- Before and after scores were not recorded for this place.")
	end

	section("ALTERNATIVES")
	for index, option in place.alternatives do
		add(string.format("- Option %s: %s | Pros: %s | Cons: %s", string.char(64 + index), Text.pick(option.text), Text.pick(option.pros), Text.pick(option.cons)))
	end

	section("RECOMMENDATION")
	add(Text.pick(recommendation.text))

	section("TRADE-OFFS")
	for _, tradeOff in ReportConfig.TradeOffs do
		add("- " .. Text.pick(tradeOff.label) .. ": " .. Text.pick(tradeOff.text))
	end

	section("ESSENTIAL LIGHTING KEPT")
	add("- " .. Text.pick(place.essential))

	section("NEXT STEPS")
	for _, category in PledgeConfig.Categories do
		for _, actionId in input.pledge[category] or {} do
			local action = findById((PledgeConfig.Actions :: any)[category] or {}, actionId)
			if action then
				add("- " .. Text.pick(action.text))
			end
		end
	end
	add("- " .. Text.pick(ReportConfig.FixedNextStep))

	section("REFLECTION")
	add(Text.pick(reflection.text))

	section("OPTIONAL REAL-WORLD OBSERVATIONS")
	add(Text.pick(ReportConfig.RealWorldNote))

	add("")
	add("END OF REPORT")
	return table.concat(lines, "\n")
end

return ReportBuilder
