local ores = {}

local nscale = 16

-- Simplification of math.fuctions call
local floor, random = math.floor, math.random

local function ncoord(xyz)
	return floor(xyz/nscale)
end

local function npos(pos)
	return {
		x = floor(pos.x/nscale),
		y = floor(pos.y/nscale),
		z = floor(pos.z/nscale),
	}
end

local function get_and_check_cid(node_name)
	local cid = minetest.get_content_id(node_name)
	assert(cid ~= 127, string.format("Unknown node \"%s\"", node_name))
	return cid
end

function cratermg.register_ore(def)
	local def = table.copy(def)
	def.c_spawns_in = get_and_check_cid(def.spawns_in)
	def.c_ore = get_and_check_cid(def.ore)
	assert(type(def.noise) == 'table',
		"Ore definition should have a 'noise' def table")

	def.noise.spread = def.noise.spread or {x=256, y=256, z=256}
	def.noise.seed = def.noise.seed or #ores + 2345
	def.noise.spread = vector.divide(def.noise.spread, nscale)

	def.nmap = {}

	ores[#ores+1] = def
end

function cratermg.ore_generate(minp, maxp, mapdata, area, p)
	local p = cratermg.profile
	local nores = #ores

	local nlens3d = {
		x=ncoord(maxp.x) - ncoord(minp.x) + 1,
		y=ncoord(maxp.y) - ncoord(minp.y) + 1,
		z=ncoord(maxp.z) - ncoord(minp.z) + 1,
	}

	local nminp = npos(minp)

	p.start('oregen noises')
	for index = 1, nores do
		ores[index].nobj = ores[index].nobj or
			minetest.get_perlin_map(ores[index].noise, nlens3d)
		ores[index].nobj:get_3d_map_flat(nminp, ores[index].nmap)
	end
	p.stop('oregen noises')

	p.start('oregen loop')
	local nix = 1
	for z = minp.z, maxp.z do
		local nixz = ncoord(z-minp.z) * nlens3d.x * nlens3d.y
		for y = minp.y, maxp.y do
			local nixy = ncoord(y-minp.y) * nlens3d.x + nixz
			local vmi = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				local nix = ncoord(x-minp.x) + nixy + 1
				local cid = mapdata[vmi]
				for index = 1, nores do
					local ore = ores[index]
					if ore.c_spawns_in == cid and
							random() < ore.nmap[nix] then
						mapdata[vmi] = ore.c_ore
						break
					end
				end
				vmi = vmi + 1
			end
		end
	end
	p.stop('oregen loop')
end
