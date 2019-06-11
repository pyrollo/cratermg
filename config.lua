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

-- Main
-------

-- Use CraterMG defined nodes ? If not, minetest nodes are used unless overiden
-- by custom config
cratermg.use_cratermg_nodes = true

-- Change sky and fog color for better ambiance
cratermg.chamge_ambiance = true

-- Mean surface level
cratermg.surface = 0

-- Levels
---------

-- Boundaries of surface map generation
cratermg.surfacemin = cratermg.surface - 200
cratermg.surfacemax = cratermg.surface + 200

-- Noises
---------

-- Mare (plains) noise. Should be quite flat (small scale)
cratermg.noises.mare = {
	seed = 1337, spread = {x=256, y=256, z=256},
    offset = cratermg.surface,
	scale = 5, octaves = 2, persist = 0.5,
}

-- Hill noise
cratermg.noises.hill = {
	spread = {x=256, y=256, z=256},
    offset = cratermg.surface -10,
	scale = 20, seed = 1338, octaves = 4, persist = 0.7,
}

-- Multipurpose small noise. Used to avoid perfect crater edges and hills.
-- Should be noisy and have an offset = 0
cratermg.noises.small = {
	spread = {x=32, y=32, z=32},
    offset = 0,	scale = 1, seed = 1339, octaves = 3, persist = 1,
}

-- Caves noises
cratermg.noises.crack1 = {
	spread = {x=128, y=256, z=128},
    offset = 0.1, scale = 1, seed = 1340, octaves = 3, persist = 1,
}

cratermg.noises.crack2 = {
	spread = {x=256, y=512, z=256},
    offset = 0.1, scale = 1, seed = 1341, octaves = 4, persist = 0.8,
}

cratermg.noises.cracksize = {
	spread = {x=256, y=256, z=256},
    offset = 0,	scale = 0.02, seed = 1342, octaves = 1, persist = 0.5,
}

-- Craters
----------

cratermg.craternumber = 0.7/(80*80) -- Number of craters (?unit?)

-- Crater probability per radius
-- Max radius is 500, fixed by scale system
-- Max proba must be 1.0 in small scale (<80)
-- Proba should decrease in larger scales (>80)
cratermg.probacurve = {
	{ r = 5, p = 0.0 },
	{ r = 7, p = 1.0 },
	{ r = 20, p = 0.005 },
	{ r = 80, p = 0.0002 },
	{ r = 390, p = 0.0001 },
	{ r = 400, p = 0.0 },
}

cratermg.fill_age = 10 -- Fill age factor (greater = more filled craters)
cratermg.wipe_age = 20 -- Wipe age factor (greater = more wiped craters)
