-- Weird Wyrmic, for Tales of Maj'Eyal.
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


local g = require 'grayswandir.utils'
local _M = loadPrevious(...)

function _M:dig(x, y, src)
	local terrain = self(x, y, _M.TERRAIN)
	if not g.get(terrain, 'dig') then return end
	local name, new, silent = terrain.dig, nil, false
	if type(terrain.dig) == 'function' then
		name, new, silent = terrain.dig(src, x, y, feat)
	end
	new = new or game.zone.grid_list[name]
	if not new then return end
	self(x, y, _M.TERRAIN, new)
	game.nicer_tiles:updateAround(game.level, x, y)
	if not silent then
		game.logSeen({x = x, y = y}, "%s is dug out, turning into %s.",
								 terrain.name:capitalize(), new.name)
	end
	return true
end

return _M
