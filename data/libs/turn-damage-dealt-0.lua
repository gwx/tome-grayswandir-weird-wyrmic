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


lib.require 'base-turn-procs'

class:bindHook('DamageProjector:final', function(self, data)
		self.base_turn_procs = self.base_turn_procs or {}
		self.base_turn_procs.damage_dealt = self.base_turn_procs.damage_dealt or {}
		local dd = self.base_turn_procs.damage_dealt
		dd[data.type] = (dd[data.type] or 0) + data.dam
		end)
