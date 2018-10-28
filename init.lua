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

local mod = {}
_G[minetest.get_current_modname()] = mod

mod.name = minetest.get_current_modname()
mod.path = minetest.get_modpath(mod.name)

mod.materials = {}
mod.noises = {}

mod.profile = dofile(mod.path..'/profile.lua')

dofile(mod.path..'/functions.lua')
dofile(mod.path..'/config.lua')
dofile(mod.path..'/mapgen.lua')
