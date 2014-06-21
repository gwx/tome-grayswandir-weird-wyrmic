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


local fireburn = DamageType.dam_def.FIREBURN.projector
DamageType.dam_def.FIREBURN.projector = function(src, x, y, type, dam)
	if src and src.inc_burn_damage then
		if _G.type(dam) == 'table' then
			dam.dam = dam.dam * (100 + src.inc_burn_damage) * 0.01
		else
			dam = dam * (100 + src.inc_burn_damage) * 0.01
		end
	end
	return fireburn(src, x, y, type, dam)
end
