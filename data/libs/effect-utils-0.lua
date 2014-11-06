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

-- List all temporary effects satisfying a filter.
superload('mod.class.Actor', function(_M)
		function _M:filterTemporaryEffects(filter)
			local effects = {}
			for id, parameters in pairs(self.tmp) do
				local effect = self.tempeffect_def[id]
				if filter(effect, parameters) then table.insert(effects, id) end
				end
			return effects
			end
		end)
