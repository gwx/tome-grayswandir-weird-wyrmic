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


superload('engine.interface.ActorTalents', function(_M)
		_M.unsustain_level_change_talents = {}

		local newTalent = _M.newTalent
		function _M:newTalent(t)
			newTalent(self, t)
			if t.unsustain_on_level_change then
				table.insert(_M.unsustain_level_change_talents, t.id)
				end
			end
		end)

superload('mod.class.Game', function(_M)
		local changeLevelReal = _M.changeLevelReal
		function _M:changeLevelReal(lev, zone, params)
			local unsustains = {}
			for _, tid in pairs(self.player.unsustain_level_change_talents or {}) do
				if self.player:isTalentActive(tid) then
					table.insert(unsustains, tid)
					self.player:forceUseTalent(tid, {no_energy = true, ignore_cd = true,})
					end
				end
			changeLevelReal(self, lev, zone, params)
			for _, tid in pairs(unsustains) do
				self.player:forceUseTalent(tid, {no_energy = true, ignore_cd = true,})
				end
			end end)
