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

-- Technic mod dependant code
-- ==========================

-- Ore nodes registration
-------------------------

minetest.register_node("cratermg:stone_with_uranium", {
	description = "Uranium Ore",
	tiles = {"default_stone.png^[colorize:#F408^technic_mineral_uranium.png"},
	is_ground_content = true,
	groups = {cracky=3, radioactive=1},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:uranium_lump",
})

minetest.register_node("cratermg:stone_with_chromium", {
	description = "Chromium Ore",
	tiles = {"default_stone.png^[colorize:#F408^technic_mineral_chromium.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:chromium_lump",
})

minetest.register_node("cratermg:stone_with_zinc", {
	description = "Zinc Ore",
	tiles = {"default_stone.png^[colorize:#F408^technic_mineral_zinc.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:zinc_lump",
})

minetest.register_node("cratermg:stone_with_lead", {
	description = "Lead Ore",
	tiles = {"default_stone.png^[colorize:#F408^technic_mineral_lead.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:lead_lump",
})

minetest.register_node("cratermg:stone_with_sulfur", {
	description = "Sulfur Ore",
	tiles = {"default_stone.png^[colorize:#F408^technic_mineral_sulfur.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:sulfur_lump",
})

-- Debris nodes registration
----------------------------

minetest.register_node("cratermg:sediment_with_uranium", {
	description = "Uranium Ore",
	tiles = {"default_cobble.png^[colorize:#F408^technic_mineral_uranium.png"},
	is_ground_content = true,
	groups = {cracky=3, radioactive=1},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:uranium_lump",
})

minetest.register_node("cratermg:sediment_with_chromium", {
	description = "Chromium Ore",
	tiles = {"default_cobble.png^[colorize:#F408^technic_mineral_chromium.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:chromium_lump",
})

minetest.register_node("cratermg:sediment_with_zinc", {
	description = "Zinc Ore",
	tiles = {"default_cobble.png^[colorize:#F408^technic_mineral_zinc.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:zinc_lump",
})

minetest.register_node("cratermg:sediment_with_lead", {
	description = "Lead Ore",
	tiles = {"default_cobble.png^[colorize:#F408^technic_mineral_lead.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
	drop = "technic:lead_lump",
})

-- Ores registration
--------------------

cratermg.register_ore({
	noise = {scale = 1, octaves = 3, persist = 1, offset = -1,
		spread = {x=1024, y=128, z=1024}},
	ore = "cratermg:stone_with_uranium", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1},
	ore = "cratermg:stone_with_chromium", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1},
	ore = "cratermg:stone_with_lead", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1},
	ore = "cratermg:stone_with_zinc", spawns_in = "cratermg:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1,
		spread = {x=256, y=1024, z=256}},
	ore = "cratermg:stone_with_sulfur", spawns_in = "cratermg:stone"
})

-- Debris registration
----------------------

cratermg.register_debris({
	name = "cratermg:sediment_with_uranium",
	chance = 3,
})

cratermg.register_debris({
	name = "cratermg:sediment_with_chromium",
	chance = 3,
})

cratermg.register_debris({
	name = "cratermg:sediment_with_zinc",
	chance = 1,
})

cratermg.register_debris({
	name = "cratermg:sediment_with_lead",
	chance = 2,
})
