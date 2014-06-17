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


local map = require 'engine.Map'

-- Keep track of all damage you do during your turn.
local hook = function(self, data)
	self.damage_done = self.damage_done or {}
	self.damage_done[data.type] = (self.damage_done[data.type] or 0) + data.dam

	local rapid = self.hasEffect and self:hasEffect('EFF_WEIRD_RAPID_STRIKES')
	if rapid and data.type == 'LIGHTNING' and data.dam > 0 then
		local target = game.level.map(data.x, data.y, map.ACTOR)
		if target == rapid.target then
			rapid.damage_done = true
		end
	end
end
class:bindHook('DamageProjector:final', hook)
