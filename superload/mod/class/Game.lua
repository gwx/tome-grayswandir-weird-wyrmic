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


local _M = loadPrevious(...)

local changeLevelReal = _M.changeLevelReal
function _M:changeLevelReal(lev, zone, params)
	local burrow = self.player:isTalentActive('T_WEIRD_BURROW')
	if burrow then self.player:forceUseTalent('T_WEIRD_BURROW', {no_energy = true, ignore_cd = true,}) end
	changeLevelReal(self, lev, zone, params)
	if burrow then self.player:forceUseTalent('T_WEIRD_BURROW', {no_energy = true, ignore_cd = true,}) end
end

return _M
