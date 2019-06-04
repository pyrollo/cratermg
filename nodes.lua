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

local planet_name = "Planet"

-- Basic nodes registration
---------------------------

minetest.register_node("cratermg:stone", {
	description = planet_name.." Stone",
	tiles = {"default_stone.png^[colorize:#F408"},
	groups = {cracky = 2},
	drop = "cratermg:sediment",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:sediment", {
	description = planet_name.." Sediments",
	tiles = {"default_cobble.png^[colorize:#F408"},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:dust", {
	description = planet_name.." Dust",
	tiles = {"default_sand.png^[colorize:#F408"},
	groups = {crumbly = 3, falling_node = 1, sand = 1},
	sounds = default.node_sound_sand_defaults(),
})

-- Ore nodes registration
-------------------------

minetest.register_node("cratermg:stone_with_coal", {
	description = "Coal Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_coal.png"},
	groups = {cracky = 3},
	drop = "default:coal_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_iron", {
	description = "Iron Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_iron.png"},
	groups = {cracky = 2},
	drop = "default:iron_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_copper", {
	description = "Copper Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_copper.png"},
	groups = {cracky = 2},
	drop = "default:copper_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_tin", {
	description = "Tin Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_tin.png"},
	groups = {cracky = 2},
	drop = "default:tin_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_mese", {
	description = "Mese Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_mese.png"},
	groups = {cracky = 1},
	drop = "default:mese_crystal",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_gold", {
	description = "Gold Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_gold.png"},
	groups = {cracky = 2},
	drop = "default:gold_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cratermg:stone_with_diamond", {
	description = "Diamond Ore",
	tiles = {"default_stone.png^[colorize:#F408^default_mineral_diamond.png"},
	groups = {cracky = 1},
	drop = "default:diamond",
	sounds = default.node_sound_stone_defaults(),
})

-- Override config
------------------

cratermg.materials.hills       = minetest.get_content_id("cratermg:stone")
cratermg.materials.mare        = minetest.get_content_id("cratermg:stone")
cratermg.materials.crater_edge = minetest.get_content_id("cratermg:sediment")
cratermg.materials.crater_fill = minetest.get_content_id("cratermg:sediment")
cratermg.materials.dust        = minetest.get_content_id("cratermg:dust")

-- Ores registration
--------------------

cratermg.register_ore({
	noise = {scale = 1, octaves = 3, persist = 1, offset = -1.3},
	ore = "cratermg:stone_with_mese", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 3, persist = 1, offset = -1.3},
	ore = "cratermg:stone_with_diamond", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 1, persist = 1 },
	ore = "cratermg:stone_with_iron", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 1, persist = 1, offset = -0.1},
	ore = "cratermg:stone_with_copper", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1},
	ore = "cratermg:stone_with_tin", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 2, octaves = 2, persist = 1, offset = -1.5},
	ore = "cratermg:stone_with_coal", spawns_in = "cratermg:stone"
})
