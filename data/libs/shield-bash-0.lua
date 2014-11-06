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


class:bindHook('Combat:attackTargetWith', function(self, data)
		local combat_shield_bash_chance = self:attr 'combat_shield_bash_chance'
		if data.hitted and not data.target.dead and
			combat_shield_bash_chance and
			rng.percent(combat_shield_bash_chance) and
			not self:attr '__shield_bash_disabled'
		then
			local shield = table.get(self:hasShield() or self, 'special_combat')
			if shield then
				self:attr('__shield_bash_disabled', 1)
				game.logSeen(self, '%s performs an additional shield bash!', self.name:capitalize())
				self:attackTargetWith(data.target, shield)
				self:attr('__shield_bash_disabled', -1)
				end
			end
		end)
