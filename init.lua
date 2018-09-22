--[[
	Crater MG - Crater Map Generator for Minetest
	(c) Pierre-Yves Rollo

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published
	by the Free Software Foundation, either version 2.1 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

local c_rock = minetest.get_content_id("default:desert_stone")
local c_dust = minetest.get_content_id("default:sand")
local c_sediment = minetest.get_content_id("default:sandstone")
local c_vacuum  = minetest.get_content_id("air")

local fill_age = 10
local wipe_age = 20

local craternumber = 0.5/(80*80)

local marenoiseparam = {
	offset = 0,
	scale = 5,
	spread = {x=256, y=256, z=256},
	seed = 1337,
	octaves = 2,
	persist = 0.5
}

local hillsnoiseparam = {
	offset = -10,
	scale = 20,
	spread = {x=256, y=256, z=256},
	seed = 1338,
	octaves = 4,
	persist = 0.7
}

local edgenoiseparam = {
	offset = 0,
	scale = 1,
	spread = {x=32, y=32, z=32},
	seed = 1339,
	octaves = 3,
	persist = 1
}

-- Undersample scale for hills noise
local us_scale = 16

-- Profiling
local counters={}

local function initcounters()
	counters = {}
end

local function startcounter(counter)
	if counters[counter] == nil then
		counters[counter] = { start = nil, total = 0 }
	end

	counters[counter].start = os.clock()
end

local function stopcounter(counter)
	counters[counter].total = counters[counter].total +
		os.clock() - counters[counter].start
	counters[counter].start = nil
end

local function showcounters()
	for name, counter in pairs(counters) do
		print (name..": "..string.format("%.2fms",counter.total*1000))
	end
end

-- Crater probability per radius
local probacurve = {
	{ r = 5, p = 0.0 },
	{ r = 7, p = 1.0 },
	{ r = 20, p = 0.005 },
	{ r = 80, p = 0.0002 },
	{ r = 350, p = 0.0001 },
	{ r = 400, p = 0.0 },
}

local function proba(radius)
	if radius < 0 then return 0 end
	local prev = { r = 0, p = 0 }
	for _, next in ipairs(probacurve) do
		if radius < next.r then
			return prev.p + (next.p - prev.p) * (radius - prev.r)
				/ (next.r - prev.r)
		end
		prev = next
	end
	return 0
end

-- Scales
local scales = {
	{ seed = 1234, rmin = 0, rmax = 80, mapsize = 80, maxproba = 1 },
	{ seed = 5678, rmin = 80, rmax = 400, mapsize = 400, maxproba = proba(80) },
}

-- Scale calculated fields
local maxscalesize = 0

for _, scale in pairs(scales) do
	-- sector seed y multiplier
	scale.zseed = math.floor(32768 / scale.mapsize)

	-- number of crater attemps multiplier (depends on the max proba and the map size)
	scale.nummult =  scale.maxproba * (scale.rmax - scale.rmin) * scale.mapsize * scale.mapsize

	if maxscalesize < scale.mapsize then maxscalesize = scale.mapsize end
end

local mapseed = 0

local function get_crater_hole_depth(crater, d2)
	return crater.depth * (crater.holeR2 - d2) / crater.holeR2
end

local function get_crater_fill_depth(crater, d2)
	return get_crater_hole_depth(crater, d2) * math.min(fill_age, crater.age)/fill_age
end

-- On map gen init, get map key
minetest.register_on_mapgen_init(function(mapgen_params)
		if mapgen_params.mgname ~= "singlenode" then
			minetest.log("warning", "[cratermg] Mapgen should be set to \"singlenode\"")
		end
		-- Note on map seed: Lua does not seem to be able to correctly handle 64
		-- bits integer so the 3 last digits are rounded. Same if we add small
		-- numbers to the 64bits key, rounded result will not include small
		-- number adition. So key is restricted to (inaccurate) 32 lower bits
		mapseed = mapgen_params.seed % (2^32)
	end
)

-- Map generation
minetest.register_on_generated(function (minp, maxp, blockseed)
	local tstart = os.clock()
	initcounters()
	startcounter('total')

	local gen_lengths = {
		x=maxp.x - minp.x + 1,
		y=maxp.y - minp.y + 1,
		z=maxp.z - minp.z + 1}

	local maremap = minetest.get_perlin_map(marenoiseparam, gen_lengths):get2dMap_flat({x=minp.x,y=minp.z})
	local hillsmap = minetest.get_perlin_map(hillsnoiseparam, gen_lengths):get2dMap_flat({x=minp.x,y=minp.z})
	local edgemap = minetest.get_perlin_map(edgenoiseparam, gen_lengths):get2dMap_flat({x=minp.x,y=minp.z})

	-- Undersampled hills noise
	local us_hillsnoiseparam = table.copy(hillsnoiseparam)
	us_hillsnoiseparam.spread = {
		x = hillsnoiseparam.spread.x / us_scale,
		y = hillsnoiseparam.spread.y / us_scale,
		z = hillsnoiseparam.spread.z / us_scale }

	-- Undersampled noise, covers larger scale maximum surface
	local us_noise_minp = {
		x = maxscalesize*(math.floor(minp.x/maxscalesize)-1)/us_scale,
	 	y = maxscalesize*(math.floor(minp.z/maxscalesize)-1)/us_scale,
	}
	local us_noise_maxp = {
		x = maxscalesize*(math.ceil(maxp.x/maxscalesize)+1)/us_scale,
	 	y = maxscalesize*(math.ceil(maxp.z/maxscalesize)+1)/us_scale,
	}
	local us_hillsmap = minetest.get_perlin_map(us_hillsnoiseparam, {
		x = us_noise_maxp.x - us_noise_minp.x,
		y = us_noise_maxp.y - us_noise_minp.y,
	}):get2dMap_flat(us_noise_minp)

	-- Crater inventory
	local craters = {}

	if minp.y < 50 and maxp.y > -50 then

		startcounter('crater inventory')

		for _, scale in pairs(scales) do

			-- Generate craters for sectors and neighboor sectors
			for x = math.floor(minp.x / scale.mapsize) - 1,
			        math.ceil(maxp.x / scale.mapsize) do
				for z = math.floor(minp.z / scale.mapsize) - 1,
				        math.ceil(maxp.z / scale.mapsize) do
					math.randomseed(mapseed + scale.zseed * z + x + scale.seed) -- Sector seed
					for _ = 1, craternumber * scale.nummult do
						local radius = scale.rmin  + (scale.rmax - scale.rmin) * math.random()
						if math.random() * scale.maxproba < proba(radius) then
							local crater = {
								x = x * scale.mapsize + math.random(scale.mapsize-1),
								z = z * scale.mapsize + math.random(scale.mapsize-1),
								totalR = radius,
								totalR2 = radius * radius,
								depth = radius * (math.random() * 0.3 + 0.3),
								age = math.sqrt(radius) * (math.random()*0.7 + 0.3),
							}
							-- Check crater intersects with map chunck
							crater.minp = { x = crater.x - crater.totalR, z = crater.z - crater.totalR }
							crater.maxp = { x = crater.x + crater.totalR, z = crater.z + crater.totalR }

							crater.holeR = 0.8 * radius - 3
							crater.holeR2 = crater.holeR * crater.holeR

							if crater.maxp.x > minp.x and
							   crater.minp.x < maxp.x and
							   crater.maxp.z > minp.z and
							   crater.minp.z < maxp.z then
								table.insert(craters, crater)
							end
						end
					end
				end
			end
		end

		-- Sort by age
		table.sort(craters, function(a,b) return a.age>b.age end)

		-- Compute impact heights and remove impacts on hills
		local index = 1
		while index <= #craters do

			local crater = craters[index]

			for oldindex = index-1, 1, -1 do
				local oldcrater = craters[oldindex]
				if crater.x>=oldcrater.minp.x and crater.x<=oldcrater.maxp.x and
				   crater.z>=oldcrater.minp.z and crater.z<=oldcrater.maxp.z
				then
					local d2 = (oldcrater.x-crater.x) * (oldcrater.x-crater.x) +
						(oldcrater.z-crater.z) * (oldcrater.z-crater.z)
					if d2 < oldcrater.holeR2 then
						crater.y = oldcrater.y
							- get_crater_hole_depth(oldcrater, d2)
							+ get_crater_fill_depth(oldcrater, d2)
						goto found
					end
				end
			end

			::found::

			-- Check crater center is not on hills (only if not yet in a crater)
			if crater.y == nil and
				us_hillsmap[1 + math.floor(crater.x/us_scale) - us_noise_minp.x
				+ (math.floor(crater.z/us_scale) - us_noise_minp.y)
				* (us_noise_maxp.x - us_noise_minp.x)] < -10 then
				crater.y = 0
			end

			if crater.y == nil then
				table.remove(craters, index)
			else
				index = index + 1
			end
		end

		stopcounter('crater inventory')
	end

	-- Get the vmanip mapgen object and the nodes and VoxelArea
	startcounter('get voxelarea')
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	stopcounter('get voxelarea')

 	startcounter('main loop')

	local vi = area:index(minp.x, minp.y, minp.z)

	local yinc = area:index(minp.x, minp.y + 1, minp.z) - vi
	local zinc = area:index(minp.x, minp.y, minp.z + 1) - vi

	local perlin_index = 1

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local hillsheight = hillsmap[perlin_index] + edgemap[perlin_index] * 10
			local mareheight = maremap[perlin_index]
			local rockheight, fillheight, edgeheight
			local holeheight, oldheight

			rockheight = math.max(mareheight, hillsheight)
			fillheight = mareheight
			edgeheight = mareheight

			if craters then
				startcounter('crater generation')
				for _, crater in pairs(craters) do
					if crater.maxp.x >= x and crater.minp.x <= x and
					   crater.maxp.z >= z and crater.minp.z <= z
					then
						local d2 = (x-crater.x)*(x-crater.x)
							+(z-crater.z)*(z-crater.z)

						if d2 <= crater.totalR2 then
							-- Hole
							holeheight = mareheight + crater.y
								- get_crater_hole_depth(crater, d2)

							-- Everything inside hole is removed
							rockheight = math.min(rockheight, holeheight)
							fillheight = math.min(fillheight, holeheight)

							-- Fill with dust according to age
							if d2 <= crater.holeR2 then
								fillheight = fillheight + get_crater_fill_depth(crater, d2)
								edgeheight = math.min(edgeheight, fillheight)
							else
								edgeheight = math.min(edgeheight, holeheight)
							end

							-- Edge
							if d2 >= crater.holeR2 then
								edgeheight = edgeheight
									+ math.max(0, wipe_age - crater.age)
									/ wipe_age * math.min(
									crater.depth * (d2 - crater.holeR2) / crater.holeR2,
									(edgemap[perlin_index]+2) * ((crater.totalR2 - crater.holeR2) / (1 + d2 - crater.holeR2) - 1))
							end
						end
					end
				end
 				stopcounter('crater generation')
			end

			startcounter('yloop')

			for y = minp.y, maxp.y do
				if y < rockheight then
					data[vi] = c_rock
				elseif y < math.max(edgeheight, fillheight) then
					data[vi] = c_sediment
				elseif y < math.max(rockheight, edgeheight, fillheight) + 1 then
					data[vi] = c_dust
				else
					data[vi] = c_vacuum
				end
				vi = vi + yinc
			end
	stopcounter('yloop')
			perlin_index = perlin_index + 1
			vi = vi - (maxp.y - minp.y + 1) * yinc + 1
		end
		vi = vi + zinc - (maxp.x - minp.x + 1)
	end
	stopcounter('main loop')

	-- Save to map
	startcounter('save')
	vm:set_data(data)
	vm:write_to_map()
	stopcounter('save')
	stopcounter('total')

	showcounters()
	print("generation "..(minetest.pos_to_string(minp)).." - "..(minetest.pos_to_string(maxp))..
	" took ".. string.format("%.2fms", (os.clock() - tstart) * 1000))
end)
