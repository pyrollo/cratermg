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

dofile(cratermg.path..'/functions.lua')
dofile(cratermg.path..'/config.lua')
dofile(cratermg.path..'/oregen.lua')
dofile(cratermg.path..'/mapgen.lua')

if cratermg.use_cratermg_nodes then
	dofile(cratermg.path..'/nodes.lua')
end
