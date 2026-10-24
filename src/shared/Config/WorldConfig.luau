--!strict
-- WorldConfig: where everything is in Byers Station and the Glarelands.
-- Positions are studs. Y is ground level (0) unless noted. Byers Station sits around the
-- origin; the Glarelands are a distorted mirror built far away (GlarelandsOffset) so each
-- region streams on its own. Mirrored places use mirror(x, z): same street, flipped east-west.

local GLARE = Vector3.new(4000, 0, 0)

local function glare(x: number, y: number, z: number): Vector3
	return GLARE + Vector3.new(x, y, z)
end

local WorldConfig = {
	GlarelandsOffset = GLARE,

	-- Region bounds on the X axis (used for the client's region look and for safety checks).
	Regions = {
		Town = { minX = -900, maxX = 900 },
		Glarelands = { minX = GLARE.X - 600, maxX = GLARE.X + 600 },
	},

	Town = {
		GroundSize = 1800,
		Spawn = Vector3.new(-150, 0.5, 30),
		-- Barn-style clubhouse: center, size (X, height, Z), and the deck telescope.
		Hub = { center = Vector3.new(-185, 0, 55), size = Vector3.new(40, 20, 30) },
		Telescope = Vector3.new(-158, 0, 24),
		-- Lantern Lane is built by the street builder around the origin (x -120..120, z = 0).
		MainRoad = { x = 150, fromZ = -230, toZ = 230, width = 20 },
		School = { center = Vector3.new(235, 0, 110), size = Vector3.new(60, 18, 40) },
		Library = { center = Vector3.new(235, 0, -60), size = Vector3.new(40, 16, 30) },
		Community = { center = Vector3.new(235, 0, -150), size = Vector3.new(50, 14, 36) },
		Parking = { center = Vector3.new(305, 0, -150), size = Vector3.new(50, 0, 64) },
		SportsFields = { center = Vector3.new(50, 0, 165), size = Vector3.new(150, 0, 90) },
		Pond = { center = Vector3.new(-210, 0, -150), radius = 45, dockLength = 22 },
		Creek = { z = -300, fromX = -600, toX = 600, width = 24 },
		Meadow = { center = Vector3.new(80, 0, -255), size = Vector3.new(320, 0, 50) },
		-- Dirt trail from Lantern Lane down to the covered bridge.
		Trail = {
			Vector3.new(-40, 0, -20),
			Vector3.new(-70, 0, -110),
			Vector3.new(-30, 0, -200),
			Vector3.new(-40, 0, -276),
		},
		TrailWidth = 9,
		-- Covered wooden bridge across the creek (runs north-south).
		Bridge = { center = Vector3.new(-40, 0, -300), length = 48, width = 14, height = 12 },
		RiftPosition = Vector3.new(-40, 6, -300),
	},

	Glarelands = {
		GroundSize = 1000,
		-- Players arrive at the west end of the mirrored Lantern Lane (Leo's Glare Gate).
		Arrival = glare(-150, 0.5, 0),
		RiftPosition = glare(-165, 6, 0),
	},

	-- Where the three friends stand during each part of the story.
	CompanionStations = {
		hub = {
			lookAt = Vector3.new(-158, 0, 24),
			Aadi = Vector3.new(-150, 0, 34),
			Aditya = Vector3.new(-145, 0, 28),
			Adrika = Vector3.new(-150, 0, 20),
		},
		lane = {
			lookAt = Vector3.new(-40, 0, 0),
			Aadi = Vector3.new(-76, 0, 27),
			Aditya = Vector3.new(-71, 0, 28),
			Adrika = Vector3.new(-66, 0, 27),
		},
		bridge = {
			lookAt = Vector3.new(-40, 0, -300),
			Aadi = Vector3.new(-50, 0, -264),
			Aditya = Vector3.new(-40, 0, -260),
			Adrika = Vector3.new(-30, 0, -264),
		},
		glare_leo = {
			lookAt = glare(0, 0, 0),
			Aadi = glare(-125, 0, 26),
			Aditya = glare(-120, 0, 28),
			Adrika = glare(-115, 0, 26),
		},
	},

	-- Places a "reach" mission step waits for. Anyone inside the radius completes it.
	Triggers = {
		bridge = { position = Vector3.new(-40, 0, -288), radius = 18 },
		glare_arrival = { position = glare(-150, 0, 0), radius = 25 },
	},

	-- Things a player can use with a prompt ("interact" mission steps).
	Interactables = {
		telescope = { position = Vector3.new(-158, 0, 24), actionKey = "prompt_telescope", objectKey = "prompt_telescope_object" },
	},

	-- Touching near one of these sets your "Get unstuck" return point.
	Checkpoints = {
		hub = Vector3.new(-150, 0.5, 30),
		lane = Vector3.new(-90, 0.5, 16),
		bridge = Vector3.new(-40, 0.5, -262),
		glare_arrival = glare(-140, 0.5, 0),
	},
	CheckpointRadius = 14,

	-- Readable navigation signs (UIText keys). facing = direction the sign text faces, in degrees.
	Signposts = {
		{ position = Vector3.new(-130, 0, 12), facingDegrees = 90, textKey = "sign_hub" },
		{ position = Vector3.new(-48, 0, -24), facingDegrees = 0, textKey = "sign_trail" },
		{ position = Vector3.new(138, 0, 14), facingDegrees = 270, textKey = "sign_civic" },
		{ position = Vector3.new(-160, 0, -112), facingDegrees = 0, textKey = "sign_pond" },
		{ position = Vector3.new(30, 0, 112), facingDegrees = 180, textKey = "sign_fields" },
		{ position = Vector3.new(-52, 0, -270), facingDegrees = 0, textKey = "sign_bridge" },
	},
}

return WorldConfig
