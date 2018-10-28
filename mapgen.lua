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

local mod = _G[minetest.get_current_modname()]

--[[
Terminology

Base map:
rock : hills rock
mare : plains

Craters :
edge : edge sedimentation
fill : filling sedimentation
mineral : minerals+sediment
hole : crater hole

*_curve: an abstract curve
*_height: relative height of a layer (=thickness)
*_level: absolute level of a layer (usualy top)
]]

local mineralstotalchance = 0
for _, mineral in ipairs(cratermg.minerals) do
	mineralstotalchance = mineralstotalchance + mineral.chance
	if mineral.mineral then
		mineral.cid = minetest.	get_content_id(mineral.mineral)
	end
end

-- Simplification of math.fuctions call
local min = math.min
local max = math.max
local ceil = math.ceil
local floor = math.floor
local random = math.random

-- On map gen init, get map seed
local mapseed = 0

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

-- Caclulate noise amplitude once for all
local edge_noise_amplitude = mod.get_noise_amplitude(cratermg.noises.edge)

-- Undersample scale for hills noise
local us_scale = 16

local function proba(radius)
	if radius < 0 then return 0 end
	local prev = { r = 0, p = 0 }
	for _, next in ipairs(cratermg.probacurve) do
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

-- Reused mapgen vars
local mapdata = {}
local marenoise, hillnoise, edgenoise, cav1noise, cav2noise
local maremap = {}
local hillmap = {}
local edgemap = {}
local cav1map = {}
local cav2map = {}
local us_hillmap = {} -- Undersampled map for gross hill detection


-- Standard curves functions
local function get_peak_curve(d2, r2, dispertion)
	-- d2 : distance^2 from center
	-- r2 : ray^2 at which curve intersects 0
	-- dispertion : shape of the peak (small value = thin peak)
	return dispertion * (r2 - d2) / r2 / (d2 + dispertion)
 end

local function get_parabolic_curve(d2, r2)
	-- d2 : distance^2 from center
	-- r2 : ray^2 at which curve intersects 0
	return (r2 - d2) / r2
end

local function get_fill_height(crater, d2)
	return get_parabolic_curve(d2, crater.holeR2) * crater.depth / 2 -- TODO, use AGE
end

local function get_hole_height(crater, d2)
	return get_parabolic_curve(d2, crater.holeR2) * crater.depth
end

-- Crater inventory of all crater interserting a given map zone
local function get_craters_list(minp, maxp)
	local craters = {}

	-- Undersampled hills noise
	local us_hillnoiseparam = table.copy(cratermg.noises.hill)
	us_hillnoiseparam.spread = {
		x = cratermg.noises.hill.spread.x / us_scale,
		y = cratermg.noises.hill.spread.y / us_scale,
		z = cratermg.noises.hill.spread.z / us_scale }

	-- Undersampled noise, covers larger scale maximum surface
	local us_noise_minp = {
		x = maxscalesize*(floor(minp.x/maxscalesize)-1)/us_scale,
		y = maxscalesize*(floor(minp.z/maxscalesize)-1)/us_scale,
	}
	local us_noise_maxp = {
		x = maxscalesize*(ceil(maxp.x/maxscalesize)+1)/us_scale,
		y = maxscalesize*(ceil(maxp.z/maxscalesize)+1)/us_scale,
	}

	minetest.get_perlin_map(us_hillnoiseparam, {
		x = us_noise_maxp.x - us_noise_minp.x,
		y = us_noise_maxp.y - us_noise_minp.y,
	}):get2dMap_flat(us_noise_minp, us_hillmap)

	for _, scale in pairs(scales) do

		-- Generate craters for sectors and neighboor sectors
		for x = floor(minp.x / scale.mapsize) - 1,
				ceil(maxp.x / scale.mapsize) do
			for z = floor(minp.z / scale.mapsize) - 1,
					ceil(maxp.z / scale.mapsize) do
				math.randomseed(mapseed + scale.zseed * z + x + scale.seed) -- Sector seed

				for _ = 1, cratermg.craternumber * scale.nummult do
					local radius = scale.rmin  + (scale.rmax - scale.rmin) * random()
					if random() * scale.maxproba < proba(radius) then
						local crater = {
							x = x * scale.mapsize + random(scale.mapsize-1),
							z = z * scale.mapsize + random(scale.mapsize-1),
							totalR = radius,
							totalR2 = radius * radius,
							depth = radius * (random() * 0.3 + 0.3),
							age = math.sqrt(radius) * (random()*0.7 + 0.3),
						}

						-- Chose a mineral type for this crater
						local mineralchance = random(mineralstotalchance)
						--TODO:Improve ugly code
						for _, mineral in ipairs(cratermg.minerals) do
							if mineralchance > 0 then
								mineralchance = mineralchance - mineral.chance
								if mineralchance <= 0 then
									crater.mineral = {
										cid = mineral.cid,
										basechance = crater.depth * crater.depth / 500,
									 }
								 end
							end
						end

						-- For consistance sake, no random stuff beyond here
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
						- get_hole_height(oldcrater, d2)
						+ get_fill_height(oldcrater, d2)
					goto craterfound
				end
			end
		end

		::craterfound::

		-- Check crater center is not on hills (only if not yet in a crater)
		if crater.y == nil and
			us_hillmap[1 + floor(crater.x/us_scale) - us_noise_minp.x
			+ (floor(crater.z/us_scale) - us_noise_minp.y)
			* (us_noise_maxp.x - us_noise_minp.x)] < -10 then
			crater.y = 0
		end

		if crater.y == nil then
			table.remove(craters, index)
		else
			index = index + 1
		end
	end

	return craters
end

-- Map generation
minetest.register_on_generated(function (minp, maxp, blockseed)
	local tstart = os.clock()
	local p = cratermg.profile
	p.init()
	p.start('total')

	-- Crater inventory
    -------------------

	local craters
	if minp.y < 50 and maxp.y > -200 then
		p.start('crater inventory')
		craters = get_craters_list(minp, maxp)
		p.stop('crater inventory')
	else
		craters = {}
	end

   -- Map generation
    -----------------
	local c = cratermg.materials

	local chulens3d = {
		x=maxp.x - minp.x + 1,
		y=maxp.y - minp.y + 1,
		z=maxp.z - minp.z + 1}

	marenoise = marenoise or minetest.get_perlin_map(cratermg.noises.mare, chulens3d)
	hillnoise = hillnoise or minetest.get_perlin_map(cratermg.noises.hill, chulens3d)
	edgenoise = edgenoise or minetest.get_perlin_map(cratermg.noises.edge, chulens3d)
--	cav1noise = edgenoise or minetest.get_perlin_map(cav1noiseparam, chulens3d)
--	cav2noise = edgenoise or minetest.get_perlin_map(cav2noiseparam, chulens3d)

	marenoise:get2dMap_flat({x=minp.x,y=minp.z}, maremap)
	hillnoise:get2dMap_flat({x=minp.x,y=minp.z}, hillmap)
	edgenoise:get2dMap_flat({x=minp.x,y=minp.z}, edgemap)
--	cav1noise:get3dMap_flat(minp, cav1map)
--	cav2noise:get3dMap_flat(minp, cav2map)

	-- Get the vmanip mapgen object and the nodes and VoxelArea
	p.start('get voxelarea')
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(mapdata)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	p.stop('get voxelarea')

 	p.start('main loop')

    -- Voxel manip index
	local vmi = area:index(minp.x, minp.y, minp.z)

    -- Y and Z increments of voxel manip index
	local yinc = area:index(minp.x, minp.y + 1, minp.z) - vmi
	local zinc = area:index(minp.x, minp.y, minp.z + 1) - vmi

	local noise2dix = 1
	local noise3dix = 1

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do

			-- Base rock + mare generation (must be before crater generation)
			p.start('base generation')
			local hill_level = hillmap[noise2dix] + edgemap[noise2dix] * 10
			local mare_level = maremap[noise2dix]
			local ground_level = max(hill_level, mare_level)

			local vmi2 = vmi -- Voxel manip index for y loop
			for y = minp.y, maxp.y do
				if y < floor(hill_level) then
					mapdata[vmi2] = c.hills
				elseif y < floor(mare_level) then
					mapdata[vmi2] = c.mare
				else
					mapdata[vmi2] = c.vacuum
				end
                vmi2 = vmi2 + yinc
			end
			p.stop('base generation')

			-- Crater generation
			p.start('crater generation')
			for _, crater in pairs(craters) do
				if crater.maxp.x >= x and crater.minp.x <= x and
				   crater.maxp.z >= z and crater.minp.z <= z
				then
					local d2 = (x-crater.x)*(x-crater.x)
						+(z-crater.z)*(z-crater.z)

					if d2 <= crater.totalR2 then
						-- Min and max level of changes in map due to the crater
						local min_level = ground_level
						local max_level = ground_level

						-- Heights and levels
						local remains_curve = get_peak_curve(d2, crater.holeR2, 20)
						local edge_height = get_peak_curve(d2, crater.totalR2, 5)
							* crater.totalR2
 							* (edgemap[noise2dix] / edge_noise_amplitude + 1)
--							(math.abs(edgemap[noise2dix]) * (min(age/maxage,1)) + (maxage - age)/maxage)
						local fill_height = get_fill_height(crater, d2)
						local hole_level = crater.y - get_hole_height(crater, d2)

						-- Ejected sediments
						edge_level = ground_level + edge_height --(+age noise?)

						ground_level = max(ground_level, edge_level)
						max_level = max(max_level, ground_level)

						-- Dig crater hole
						edge_level = min(hole_level, edge_level)
						ground_level = min(hole_level, ground_level)

						min_level = min(min_level, ground_level)

						-- Fill hole
						if d2 < crater.holeR2 then
							-- Add remains zone
							remains_level = ground_level + min(fill_height,
								floor(remains_curve*crater.depth/5 + random()))

							-- Fill
							fill_level = ground_level + fill_height

							ground_level = max(remains_level, fill_level)
							max_level = max(max_level, ground_level)

						else
							fill_level = ground_level
							remains_level = ground_level
						end

						-- Y loop
						if min_level < maxp.y+1 and max_level >= minp.y then
							min_level = min(max(floor(min_level), minp.y), maxp.y)
							max_level = min(max(ceil(max_level), minp.y), maxp.y)

							vmi2 = vmi + (min_level - minp.y) * yinc
							for y = min_level, max_level do
--								yr = y + random()
								if y < floor(edge_level) then
									mapdata[vmi2] = c.crater_edge
								elseif y < floor(remains_level) then
								-- TODO : MIX UP MINERALS
		--							mapdata[vmi2] = c_crater_fill
			if random()< remains_curve*(remains_level-y)/10 then
									mapdata[vmi2] = crater.mineral.cid
			else
				mapdata[vmi2] = c.crater_fill
			end
								elseif y < floor(fill_level) then
									mapdata[vmi2] = c.crater_fill
								else
									mapdata[vmi2] = c.vacuum
								end
								vmi2 = vmi2 + yinc
							end
						end
					end
				end
			end -- Crater loop
			p.stop('crater generation')

			--Dust generation
			if ground_level >= minp.y and ground_level <= maxp.y then
				vmi2 = vmi + yinc * (ground_level - minp.y)
				mapdata[vmi2] = c.dust
			end
			noise2dix = noise2dix + 1

			vmi = vmi  + 1
		end -- Z loop
		vmi = vmi + zinc - (maxp.x - minp.x + 1)
    end -- X loop

	p.stop('main loop')

	-- Save to map
	p.start('save')
	vm:set_data(mapdata)
	vm:write_to_map()
	p.stop('save')
	p.stop('total')

	p.show()
--	print("generation "..(minetest.pos_to_string(minp)).." - "..(minetest.pos_to_string(maxp))..
--	" took ".. string.format("%.2fms", (os.clock() - tstart) * 1000))
end)
