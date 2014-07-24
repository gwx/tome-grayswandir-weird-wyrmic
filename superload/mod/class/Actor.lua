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

function _M:on_inflict_effect(effect, actor)
	if effect.subtype.wound and self:attr 'equilibrium_on_wound' then
		self:incEquilibrium(-self:attr 'equilibrium_on_wound')
	end
end

local on_set_temporary_effect = _M.on_set_temporary_effect
function _M:on_set_temporary_effect(eff_id, e, p)
	if not e.src then e.src = game.current_actor end
	local ret = {on_set_temporary_effect(self, eff_id, e, p)}
	if e.src then e.src:on_inflict_effect(e, self) end
	return unpack(ret)
end

local act = _M.act
function _M:act()
	game.current_actor = self
	local ret = {act(self)}
	game.current_actor = nil
	return unpack(ret)
end

return _M
