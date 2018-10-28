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

-- Computes noise amplitude (actually half amplitude, can go form -amplitude
-- to + amplitude)
function mod.get_noise_amplitude(noise_params)
	if (noise_params.persist == 1) then
		return noise_params.octaves * noise_params.scale
	else
		return noise_params.scale *
			(noise_params.persist ^ noise_params.noise_params.octaves - 1)
			/ (noise_params.persist - 1)
	end
end
