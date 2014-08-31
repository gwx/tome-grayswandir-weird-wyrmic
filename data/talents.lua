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


Talents.recalc_draconic_form = function(self, t)
 	self:updateTalentTypeMastery('wild-gift/draconic-form')
end

Talents.cooldown_group = function(self, t, cd)
	local tt = self:getTalentTypeFrom(t.type[1])
	for _, talent in pairs(tt.talents) do
		if talent.id ~= t.id and self:knowTalent(talent) then
			self:callTalent(talent.id, 'set_group_cooldown', cd)
		end
	end
end

for _, file in pairs {
	'draconic-form', 'draconic-might',
	'fire-aspect', 'ice-aspect', 'lightning-aspect', 'sand-aspect',
	'blade-aspect', 'stone-aspect',
	'misc',
	--'stone-aspect', 'wind-aspect',
										 }
do
	load('/data-grayswandir-weird-wyrmic/talents/'..file..'.lua')
end
