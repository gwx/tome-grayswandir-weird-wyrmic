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

-- Generic Scaling Function
-- Examples:
--
-- self:wwScale {min = 10, max = 50, stat = 'str',}
-- Returns 10 at 10 str, 50 at 100 str, and 77 at 200 str.
--
-- self:wwScale {max = 50, limit = 100, stat = 'str',}
-- Returns 16.67 at 10 str, 50 at 100 str, and 65.4 at 200 str.
--
-- self:wwScale {min = 1.2, max = 1.9, talent = t,}
-- Returns 1.2 at talent level 1 and 1.9 at talent level 5
--
-- self:wwScale {min = 3, max = 7, talent = t, stat = 'cun', round = 'floor',}
-- At talent level 1, cunning 10:   3.00
-- At talent level 5, cunning 10:   5.55 (floored to 5.00)
-- At talent level 5, cunning 100:  7.00
function _M:wwScale(t)
	local value = 5
	if t.talent then value = value * 0.2 * self:getTalentLevel(t.talent) end

	if t.mult then value = (value - 1) * t.mult + 1 end

	if t.stat then
		-- For both a talent and stat, the stat = 0 is at 50% power.
		if t.talent then
			value = ((value - 1) * (self:getStat(t.stat) + 100) * 0.005) + 1
		-- For scaling only on a stat, the stat = 10 is at 0% power.
		else
			value = ((value - 1) * (self:getStat(t.stat) - 10) / 90) + 1
		end
	end

	local power
	if t.power == 'attack' then power = self:combatAttack()
	elseif t.power == 'physical' then power = self:combatPhysicalpower()
	elseif t.power == 'mind' then power = self:combatMindpower()
	elseif t.power == 'spell' then power = self:combatSpellpower()
	end
	if power then
		-- For both a talent and power, the power = 0 is at 50% power.
		if t.talent then
			value = ((value - 1) * (power + 100) * 0.005) + 1
		-- For scaling only on a power, the power = 0 is at 0% power.
		else
			value = ((value - 1) * power * 0.01) + 1
		end
	end

	if t.limit then
		value = self:combatTalentLimit(value, t.limit, t.min, t.max)
	else
		value = self:combatTalentScale(value, t.min, t.max)
	end

	if t.round == 'floor' then value = math.floor(value)
	elseif t.round == 'ceil' then value = math.ceil(value)
	end

	if t.scale == 'damage' then value = self:rescaleDamage(value) end

	return value
end

return _M
