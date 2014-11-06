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


local damage_type = require 'engine.DamageType'
local _M = loadPrevious(...)

local combatDamage = _M.combatDamage
function _M:combatDamage(weapon, adddammod)
	adddammod = adddammod or {}

	local str_100 = self:attr 'dammod_str_100_mult'
	local str = table.get(weapon, 'dammod', 'str')
	if str_100 and str and str > 1 then
		adddammod.str = (adddammod.str or 0) + (str - 1) * str_100 * 0.01
	end

	return combatDamage(self, weapon, adddammod)
end

local combatSpeed = _M.combatSpeed
function _M:combatSpeed(weapon)
	local speed = combatSpeed(self, weapon)
	weapon = weapon or self.combat or {}
	local shield_speed = self:attr 'combat_shield_speed'
	if shield_speed and weapon.talented == 'shield' then
		speed = speed / math.max((100 + shield_speed) * 0.01, 0.1)
	end
	return speed
end

return _M
