--!strict
-- PledgeRules: pure validation of a pledge sent by a client. Returns a clean
-- { category = { actionIds } } (at least one, at most MaxPerCategory, known ids, no repeats)
-- or nil if anything is off. The server saves only this cleaned copy.

local PledgeConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("PledgeConfig"))

local PledgeRules = {}

function PledgeRules.clean(choices: any): { [string]: { string } }?
	if typeof(choices) ~= "table" then
		return nil
	end
	local result = {}
	for _, category in PledgeConfig.Categories do
		local picked = choices[category]
		if typeof(picked) ~= "table" or #picked == 0 or #picked > PledgeConfig.MaxPerCategory then
			return nil
		end
		local valid: { [string]: boolean } = {}
		for _, action in (PledgeConfig.Actions :: any)[category] do
			valid[action.id] = true
		end
		local list = {}
		local seen = {}
		for _, actionId in picked do
			if typeof(actionId) ~= "string" or not valid[actionId] or seen[actionId] then
				return nil
			end
			seen[actionId] = true
			table.insert(list, actionId)
		end
		result[category] = list
	end
	return result
end

return PledgeRules
