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

local profile={}

-- Profiling
local counters={}

function profile.init()
	counters = {}
end

function profile.start(counter)
	if counters[counter] == nil then
		counters[counter] = { start = nil, total = 0 }
	end

	counters[counter].start = os.clock()
end

function profile.stop(counter)
	counters[counter].total = counters[counter].total +
		os.clock() - counters[counter].start
	counters[counter].start = nil
end

function profile.show()
	for name, counter in pairs(counters) do
		print (name..": "..string.format("%.2fms",counter.total*1000))
	end
end

return profile