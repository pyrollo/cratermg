cratermg.registered_ores = {}
--[[
	chance = 0.7, -- 1 = infinite number of ore spots in mapblock (dont do it!!) 0 = none
	minray = 50, maxray = 100, -- Min max ray size
	nodes = { -- Types of nodes appearing in this spot, may be several
		{
			ore = "cratermg:mese",
			spawns_in = "cratermg:stone",
			chance_offset = 0.7, -- Added to random before testing. Lowers chances
		},
		{
			spawns_in = "cratermg:stone",
			spawns = "cratermg:mese",
		},
}
]]

-- Simplification of math.fuctions call
local min, max, ceil, floor, random =
	math.min, math.max, math.ceil, math.floor, math.random

local scale = { seed = 6543, mapsize = 400, xseed = 1 }
scale.yseed = math.floor(32768 / scale.mapsize)
scale.zseed = math.floor(32768 / scale.mapsize) * scale.yseed

local function get_and_check_cid(node_name)
	local cid = minetest.get_content_id(node_name)
	assert(cid ~= 127, string.format("Unknown node \"%s\"", node_name))
	return cid
end

function cratermg.register_ore(def)
	local def = table.copy(def)
	assert(def.chance < 1, "Chance must be strictly lesser than 1.0")
	if def.nodes then
		for _, node in ipairs(def.nodes) do
			node.c_spawns_in = get_and_check_cid(node.spawns_in)
			node.c_ore = get_and_check_cid(node.ore)
		end
	end
	cratermg.registered_ores[#cratermg.registered_ores+1] = def
end

local function get_spots_list(minp, maxp)
	local spots = {}
	-- Sector scan (a sector is a cube of mapsize ^ 3 nodes)
	for x = floor(minp.x / scale.mapsize) - 1,
			ceil(maxp.x / scale.mapsize) do
		for y = floor(minp.y / scale.mapsize) - 1,
				ceil(maxp.y / scale.mapsize) do
			for z = floor(minp.z / scale.mapsize) - 1,
					ceil(maxp.z / scale.mapsize) do
				math.randomseed( -- Sector seed
					cratermg.mapseed + scale.zseed * z + scale.yseed * y
					 	+ scale.xseed * x + scale.seed)
				for _, ore in ipairs(cratermg.registered_ores) do
					while (random() < ore.chance) do
						local spot = {
							x = x * scale.mapsize + random(scale.mapsize-1),
							y = y * scale.mapsize + random(scale.mapsize-1),
							z = z * scale.mapsize + random(scale.mapsize-1),
							r = random(ore.minray , ore.maxray),
							ore = ore,
						}
						spot.r2 = spot.r * spot.r
						spots[#spots+1] = spot
					end
				end
			end
		end
	end

	return spots
end

function cratermg.ore_generate(minp, maxp, mapdata, area, p)
	local spots = get_spots_list(minp, maxp)

  -- Reorganize by spawns_in content id
	local spots_by_cid = {}
	for _, spot in ipairs(spots) do
		local nodes_by_cid = {}
		for _, node in ipairs(spot.ore.nodes) do
			local cid = node.c_spawns_in
			nodes_by_cid[cid] = nodes_by_cid[cid] or {}
			nodes_by_cid[cid][#nodes_by_cid[cid]+1] = {
				c_ore = node.c_ore,
				chance_offset = node.chance_offset,
			}
		end
		for cid, nodes in pairs(nodes_by_cid) do
			spots_by_cid[cid] = spots_by_cid[cid] or {}
			spots_by_cid[cid][#spots_by_cid[cid]+1] = {
				r = spot.r, r2 = spot.r2, x = spot.x, y = spot.y, z = spot.z,
				nodes = nodes,
			}
		end
	end

	-- Check each node for ore spawning
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			local vmi = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				local spots = spots_by_cid[mapdata[vmi]]
				if spots then
					for i = 1, #spots do
						local spot = spots[i]
						local sx, sy, sz, sr, sr2 = spot.x, spot.y, spot.z, spot.r, spot.r2
						if  x > sx-sr and x < sx+sr
						and y > sy-sr and y < sy+sr
						and z > sz-sr and z < sz+sr then
	--local d2 = (x-spot.x) ^ 2 + (y-spot.y) ^ 2 + (z-spot.z) ^ 2
--							local d2 = (x-spot.x) * (x-spot.x) + (y-spot.y) * (y-spot.y) + (z-spot.z) * (z-spot.z)
local d2=0
							if d2 < sr2 then
--								local rnd = random()
--								rnd = rnd * rnd * rnd
local rnd = 0.5
								local ratio = d2/sr2
								for j = 1, #spot.nodes do
									if rnd > ratio + (spot.nodes[j].chance_offset or 0) then
										mapdata[vmi] = spot.nodes[j].c_ore
										break
									end
								end
							end
						end
					end
				end
				vmi = vmi + 1
			end
		end
	end

end
