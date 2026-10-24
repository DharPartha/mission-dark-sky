--!strict
-- StreetBuilder: Lantern Lane (road, sidewalks, crosswalk, driveway, three houses, and the
-- crossing sign) built around `origin`. The Glarelands use the same street mirrored
-- east-west with the corrupted palette and slightly warped houses, so the place is
-- recognizable in both worlds. Fixture positions in FixtureConfig follow the same layout.

local Parts = require(script.Parent:WaitForChild("Parts"))

local StreetBuilder = {}

function StreetBuilder.build(parent: Instance, origin: Vector3, mirror: boolean, palette: Parts.Palette, warped: boolean)
	local folder = Parts.makeFolder("LanternLane", parent)
	local flip = if mirror then -1 else 1
	local function at(x: number, y: number, z: number): CFrame
		return CFrame.new(origin + Vector3.new(x * flip, y, z))
	end

	Parts.makePart({ name = "Road", size = Vector3.new(240, 0.2, 24), cframe = at(0, 0.1, 0), color = palette.road, material = Enum.Material.Asphalt, parent = folder })
	for x = -110, 110, 16 do
		Parts.makePart({ name = "LaneMark", size = Vector3.new(7, 0.05, 0.5), cframe = at(x, 0.22, 0), color = palette.stripe, canCollide = false, parent = folder })
	end
	for _, z in { 16, -16 } do
		Parts.makePart({ name = "Sidewalk", size = Vector3.new(240, 0.5, 8), cframe = at(0, 0.25, z), color = palette.sidewalk, material = Enum.Material.Concrete, parent = folder })
	end
	-- Crosswalk next to the safety-critical crossing light.
	for z = -10, 10, 3 do
		Parts.makePart({ name = "CrosswalkStripe", size = Vector3.new(6, 0.05, 1.6), cframe = at(34, 0.22, z), color = palette.stripe, canCollide = false, parent = folder })
	end
	Parts.makePart({ name = "Driveway", size = Vector3.new(12, 0.3, 14), cframe = at(6, 0.15, 27), color = palette.sidewalk, material = Enum.Material.Concrete, parent = folder })

	for index, x in { -50, 6, 60 } do
		local model = Parts.makeModel("House" .. index, folder, false)
		-- Glarelands houses lean slightly, as if seen through heat haze.
		local lean = if warped then CFrame.Angles(0, 0, math.rad((index - 2) * 4)) else CFrame.identity
		Parts.makePart({ name = "Walls", size = Vector3.new(26, 14, 20), cframe = at(x, 7, 44) * lean, color = palette.houseWalls[index], material = Enum.Material.WoodPlanks, parent = model })
		Parts.makeWedge("RoofFront", Vector3.new(27, 6, 11), at(x, 17, 38.5) * lean, palette.roof, model)
		Parts.makeWedge("RoofBack", Vector3.new(27, 6, 11), at(x, 17, 49.5) * lean * CFrame.Angles(0, math.pi, 0), palette.roof, model)
		-- Lit windows: homes whose rest the glare disturbs.
		for _, wx in { -7, 7 } do
			Parts.makePart({ name = "Window", size = Vector3.new(4, 4, 0.2), cframe = at(x + wx, 8, 33.95), color = palette.window, material = Enum.Material.Neon, canCollide = false, parent = model })
		end
		Parts.makePart({
			name = "Door",
			size = Vector3.new(4, 7, 0.3),
			cframe = at(x + (if index == 2 then 9 else 0), 3.5, 33.9),
			color = palette.wood,
			material = Enum.Material.Wood,
			parent = model,
		})
	end

	-- Crossing sign: the in-world evidence that this light keeps walkers safe.
	Parts.makeSign(origin + Vector3.new(41 * flip, 0, -18), 0, "sign_crossing", palette, folder, Vector3.new(6, 3, 0.3))
	return folder
end

return StreetBuilder
