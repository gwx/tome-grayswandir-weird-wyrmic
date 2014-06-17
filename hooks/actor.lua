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


local hook = function(self, data)

	-- equilibrium_on_damage - gain equilibrium on any turn you do that damage type.
	for type, gain in pairs(self.equilibrium_on_damage or {}) do
		if self.damage_done and self.damage_done[type] and self.damage_done[type] > 0 then
			self:incEquilibrium(-gain)
		end
	end

	self.damage_done = {}
end
class:bindHook('Actor:actBase:Effects', hook)
