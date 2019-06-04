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

local mineralstotalchance = 0
for _, mineral in ipairs(cratermg.minerals) do
	mineralstotalchance = mineralstotalchance + mineral.chance
	if mineral.mineral then
		mineral.cid = minetest.get_content_id(mineral.mineral)
	end
end

-- Simplification of math.fuctions call
local min = math.min
local max = math.max
local ceil = math.ceil
local floor = math.floor
local random = math.random

-- On map gen init, get map seed
cratermg.mapseed = 0

minetest.register_on_mapgen_init(function(mapgen_params)
		-- Note on map seed: Lua does not seem to be able to correctly handle 64
		-- bits integer so the 3 last digits are rounded. Same if we add small
		-- numbers to the 64bits key, rounded result will not include small
		-- number adition. So key is restricted to (inaccurate) 32 lower bits
		cratermg.mapseed = mapgen_params.seed % (2^32)
	end
)

-- Caclulate noise amplitude once for all
local small_noise_amplitude = mod.get_noise_amplitude(cratermg.noises.small)

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

local marenoise, hillnoise, smallnoise
local crack1noise, crack2noise, cracksizenoise

local maremap = {}
local hillmap = {}
local smallmap = {}
local crack1map = {}
local crack2map = {}
local cracksizemap = {}
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
	return get_parabolic_curve(d2, crater.holeR2) * crater.fill_mult
end

local function get_hole_height(crater, d2)
	return get_parabolic_curve(d2, crater.holeR2) * crater.depth
end

-- Computes crater influence at a given distance
-- crater: crater array containing its caracteristics
-- smallmap: value of small noise at given point
-- ground_level: ground level before the crater happens
-- d2: Square of the distance to the crater center
local function compute_crater_deformation(crater, smallmap, ground_level, d2)

	if d2 <= crater.totalR2 then
		-- Min and max level of changes in map due to the crater
		local min_level = ground_level
		local max_level = ground_level

		local fill_level, remains_level

		-- Heights and levels
		local remains_curve = get_peak_curve(d2, crater.holeR2, 20)
		local edge_height = get_peak_curve(d2, crater.totalR2, 5)
			* crater.edge_mult * (smallmap / small_noise_amplitude + 1)

		local fill_height = get_fill_height(crater, d2)
		local hole_level = crater.y - get_hole_height(crater, d2)

		-- Ejected sediments
		local edge_level = ground_level + edge_height --(+age noise?)

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

		return ground_level, min_level, max_level,
		       edge_level, remains_level, fill_level
	end
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
	}):get_2d_map_flat(us_noise_minp, us_hillmap)

	for _, scale in pairs(scales) do

		-- Generate craters for sectors and neighboor sectors
		for x = floor(minp.x / scale.mapsize) - 1,
				ceil(maxp.x / scale.mapsize) do
			for z = floor(minp.z / scale.mapsize) - 1,
					ceil(maxp.z / scale.mapsize) do
				math.randomseed( -- Sector seed
					cratermg.mapseed + scale.zseed * z + x + scale.seed)
				for _ = 1, cratermg.craternumber * scale.nummult do
					local radius = scale.rmin  + (scale.rmax - scale.rmin) * random()
					if random() * scale.maxproba < proba(radius) then
						local crater = {
							x = x * scale.mapsize + random(scale.mapsize-1),
							z = z * scale.mapsize + random(scale.mapsize-1),
							totalR = radius,
							totalR2 = radius * radius,
							depth = radius * (random() + 1) * 0.2,
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

						crater.edge_mult = crater.totalR2 *
							get_peak_curve(crater.age, cratermg.wipe_age, 1000)
						crater.fill_mult = crater.depth / (1 + max(0,
							get_peak_curve(crater.age, cratermg.fill_age, 10)))

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
	-- (this is a gross calculation)
	local index = 1
	while index <= #craters do

		local crater = craters[index]
		local incrater = false

		crater.y = cratermg.surface -- Near mare height

		-- Apply older craters transformations
		for olderindex = 1, index-1 do
			local oldercrater = craters[olderindex]
			if crater.x>=oldercrater.minp.x and crater.x<=oldercrater.maxp.x and
			   crater.z>=oldercrater.minp.z and crater.z<=oldercrater.maxp.z
			then
				local d2 =
					(oldercrater.x-crater.x) * (oldercrater.x-crater.x) +
					(oldercrater.z-crater.z) * (oldercrater.z-crater.z)
				if d2 < oldercrater.holeR2 then
					crater.y = compute_crater_deformation(oldercrater, 0,
						crater.y, d2)
					incrater = true
				end
			end
		end

		-- Check crater center is not on hills (only if not yet in a crater)
		if not incrater and
			us_hillmap[1 + floor(crater.x/us_scale) - us_noise_minp.x
			+ (floor(crater.z/us_scale) - us_noise_minp.y)
			* (us_noise_maxp.x - us_noise_minp.x)] > cratermg.surface-10
		then
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
	if minp.y < cratermg.surfacemax and maxp.y > cratermg.surfacemin then
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
	smallnoise = smallnoise or minetest.get_perlin_map(cratermg.noises.small, chulens3d)
	crack1noise = crack1noise or minetest.get_perlin_map(cratermg.noises.crack1, chulens3d)
	crack2noise = crack2noise or minetest.get_perlin_map(cratermg.noises.crack2, chulens3d)
	cracksizenoise = cracksizenoise or minetest.get_perlin_map(cratermg.noises.cracksize, chulens3d)

	marenoise:get_2d_map_flat({x=minp.x,y=minp.z}, maremap)
	hillnoise:get_2d_map_flat({x=minp.x,y=minp.z}, hillmap)
	smallnoise:get_2d_map_flat({x=minp.x,y=minp.z}, smallmap)

	crack1noise:get_3d_map_flat(minp, crack1map)
	crack2noise:get_3d_map_flat(minp, crack2map)
	cracksizenoise:get_3d_map_flat(minp, cracksizemap)

	-- Get the vmanip mapgen object and the nodes and VoxelArea
	p.start('get voxelarea')
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	vm:get_data(mapdata)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	p.stop('get voxelarea')

 	p.start('main loop')

	-- Voxel manip indexes
	local vmix, vmiy, vmiz
	vmiz = area:index(minp.x, minp.y, minp.z)

    -- Increments of voxel manip index
	local xinc = area:index(minp.x + 1, minp.y, minp.z) - vmiz
	local yinc = area:index(minp.x, minp.y + 1, minp.z) - vmiz
	local zinc = area:index(minp.x, minp.y, minp.z + 1) - vmiz

	-- Noises indexes
	local n2d = 1
	local n3dx, n3dy, n3dz
	n3dz = 1
	local n3dxinc = 1
	local n3dyinc = chulens3d.x
	local n3dzinc = chulens3d.x * chulens3d.y

	for z = minp.z, maxp.z do
		vmix = vmiz
		n3dx = n3dz
		for x = minp.x, maxp.x do
			-- Base rock + mare generation (must be before crater generation)
			p.start('base generation')
			local hill_level = hillmap[n2d] + smallmap[n2d] * 10
			local mare_level = maremap[n2d]
			local ground_level = max(hill_level, mare_level)

			vmiy = vmix
			for y = minp.y, maxp.y do
				if y < floor(hill_level) then
					mapdata[vmiy] = c.hills
				elseif y < floor(mare_level) then
					mapdata[vmiy] = c.mare
				else
					mapdata[vmiy] = c.vacuum
				end
				vmiy = vmiy + yinc
			end
			p.stop('base generation')

			-- Crater generation
			p.start('crater generation')
			local min_level, max_level, edge_level, remains_level, fill_level

			for _, crater in pairs(craters) do
				if crater.maxp.x >= x and crater.minp.x <= x and
				   crater.maxp.z >= z and crater.minp.z <= z
				then
					local d2 = (x-crater.x)*(x-crater.x) +
						(z-crater.z)*(z-crater.z)

					if d2 <= crater.totalR2 then
						ground_level, min_level, max_level,
						edge_level, remains_level, fill_level
							= compute_crater_deformation(
								crater, smallmap[n2d], ground_level, d2)
						-- Y loop (mare height added to all to introduce some noise)
						if min_level < maxp.y+1 and max_level >= minp.y then
							min_level = min(max(floor(min_level), minp.y), maxp.y)
							max_level = min(max(ceil(max_level), minp.y), maxp.y)

							vmiy = vmix + (min_level - minp.y) * yinc
							for y = min_level, max_level do
								if y < floor(edge_level) then
									mapdata[vmiy] = c.crater_edge
								elseif y < floor(remains_level) then
								-- TODO : MIX UP MINERALS
									mapdata[vmiy] = crater.mineral.cid
								elseif y < floor(fill_level) then
									mapdata[vmiy] = c.crater_fill
								else
									mapdata[vmiy] = c.vacuum
								end
								vmiy = vmiy + yinc
							end
						end
					end
				end
			end -- Crater loop
			p.stop('crater generation')

			--Dust generation
			if floor(ground_level) >= minp.y
			and floor(ground_level) <= maxp.y then
				vmiy = vmix + (floor(ground_level) - minp.y) * yinc
				mapdata[vmiy] = c.dust
			end

			p.start('cave generation')
			-- Caves
			vmiy = vmix
			n3dy = n3dx
			for y = minp.y, maxp.y do
				local proba = cracksizemap[n3dy] * (1000 - y + cratermg.surface) / 1000
				if math.abs(crack1map[n3dy]) < proba or
					math.abs(crack2map[n3dy]) < proba
				then
					mapdata[vmiy] = c.vacuum
				end
				n3dy = n3dy + n3dyinc
				vmiy = vmiy + yinc
			end
			p.stop('cave generation')

			n2d = n2d + 1
			n3dx = n3dx + n3dxinc
			vmix = vmix + xinc
		end -- Z loop

		n3dz = n3dz + n3dzinc
		vmiz = vmiz  + zinc
	end -- X loop

	p.stop('main loop')

	p.start('oregen')
 	cratermg.ore_generate(minp, maxp, mapdata, area, p)
	p.stop('oregen')

	-- Save to map
	p.start('save')
	vm:set_data(mapdata)
	vm:set_lighting( {day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map()
	p.stop('save')
	p.stop('total')
--	p.show()
--	print("generation "..(minetest.pos_to_string(minp)).." - "..(minetest.pos_to_string(maxp))..
--	" took ".. string.format("%.2fms", (os.clock() - tstart) * 1000))
end)
