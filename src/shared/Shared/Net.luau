--!strict
-- Net: names of every RemoteEvent and the shared state folder, so client and server
-- never disagree on a string. The server creates these in Bootstrap.

local Net = {}

Net.RemotesFolder = "Remotes"
Net.StateFolder = "State"

Net.Remotes = {
	-- Client -> server
	ClientReady = "ClientReady", -- () sent once UI listeners are connected
	FixtureAction = "FixtureAction", -- (fixtureId: string, verb: string, option: string)
	MoonVote = "MoonVote", -- (choice: "agree" | "doubt")
	DevRequest = "DevRequest", -- (action: "resetWorld" | "resetProfile", confirm: string) developers only
	-- Server -> client
	OpenFixtureMenu = "OpenFixtureMenu", -- (fixtureId: string)
	Notice = "Notice", -- (key: string, arg: string | number | nil, argKind: "text" | "evidence" | nil)
	Dialogue = "Dialogue", -- (lineIds: { string })
	GlareEvent = "GlareEvent", -- (kind: "telegraph" | "hit", seconds: number)
	ShowCompare = "ShowCompare", -- ()
}

-- Waits for the server-created remotes folder (client side).
function Net.waitForRemotes(root: Instance): Folder
	return root:WaitForChild(Net.RemotesFolder) :: Folder
end

return Net
