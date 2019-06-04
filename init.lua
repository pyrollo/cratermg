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

cratermg = {}

cratermg.name = minetest.get_current_modname()
cratermg.path = minetest.get_modpath(minetest.get_current_modname())

cratermg.materials = {}
cratermg.noises = {}

cratermg.profile = dofile(cratermg.path..'/profile.lua')


minetest.register_node("cratermg:stone", {
	description = "Cratermg Stone",
	tiles = {"default_stone.png^[colorize:#F408"},
	groups = {cracky = 2},
	drop = "cratermg:sediment",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:sediment", {
	description = "Cratermg Sediments",
	tiles = {"default_cobble.png^[colorize:#F408"},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:dust", {
	description = "Cratermg dust",
	tiles = {"default_sand.png^[colorize:#F408"},
	groups = {crumbly = 3, falling_node = 1, sand = 1},
	sounds = default.node_sound_sand_defaults(),
})

dofile(cratermg.path..'/functions.lua')
dofile(cratermg.path..'/config.lua')
dofile(cratermg.path..'/oregen.lua')
dofile(cratermg.path..'/mapgen.lua')

if cratermg.use_cratermg_nodes then
	dofile(cratermg.path..'/nodes.lua')
	if minetest.get_modpath('technic_worldgen') then
		dofile(cratermg.path..'/technic.lua')
	end
end

if cratermg.chamge_ambiance then
	minetest.register_on_joinplayer(function(player)
		player:set_sky("#e2aa8c", "plain")
		player:set_clouds({density=0})
	end)
end
