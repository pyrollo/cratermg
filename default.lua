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

-- Default nodes configuration
-- ===========================

-- Basic Materials
------------------

cratermg.materials.vacuum      = minetest.get_content_id("air")
cratermg.materials.hills       = minetest.get_content_id("default:stone")
cratermg.materials.mare        = minetest.get_content_id("default:stone")
cratermg.materials.crater_edge = minetest.get_content_id("default:cobble")
cratermg.materials.crater_fill = minetest.get_content_id("default:cobble")
cratermg.materials.dust        = minetest.get_content_id("default:sand")

-- Ores registration
--------------------

cratermg.register_ore({
	noise = {scale = 1, octaves = 3, persist = 1, offset = -1.3},
	ore = "default:stone_with_mese", spawns_in = "default:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 3, persist = 1, offset = -1.3},
	ore = "default:stone_with_diamond", spawns_in = "default:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 1, persist = 1 },
	ore = "default:stone_with_iron", spawns_in = "default:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 1, persist = 1, offset = -0.1},
	ore = "default:stone_with_copper", spawns_in = "default:stone"
})

cratermg.register_ore({
	noise = {scale = 1, octaves = 2, persist = 1, offset = -1},
	ore = "default:stone_with_tin", spawns_in = "default:stone"
})

cratermg.register_ore({
	noise = {scale = 2, octaves = 2, persist = 1, offset = -1.5},
	ore = "default:stone_with_coal", spawns_in = "default:stone"
})

-- Debris registration
----------------------

cratermg.register_debris({
	name = minetest.get_name_from_content_id(cratermg.materials.crater_fill),
	chance = 10,
})
