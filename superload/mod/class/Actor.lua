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

local breakLightningSpeed = _M.breakLightningSpeed
function _M:breakLightningSpeed()
	breakLightningSpeed(self)
	local weird = self:hasEffect('EFF_WEIRD_LIGHTNING_SPEED')
	if weird and not weird.is_low then
		self:removeEffect('EFF_WEIRD_LIGHTNING_SPEED')
	end
end

return _M
