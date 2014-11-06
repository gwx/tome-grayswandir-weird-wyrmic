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


local get = util.getval

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

local block = Talents.talents_def.T_BLOCK
local getBlockValue = block.getBlockValue
block.on_pre_use = function(self, t, silent)
	if not (self:hasShield() or self.special_combat) then if not silent then game.logPlayer(self, "You require a shield to use this talent.") end return false end return true
end
block.getBlockValue = function(self, t)
	local value = getBlockValue(self, t)
	if value == 0 then
		value = table.get(self, 'special_combat', 'block')
	end
	local inc = self:attr 'block_power_inc'
	if inc then value = value * (100 + inc) * 0.01 end
	return value
end
-- Block uses shield's speed.
local action = block.action
block.action = function(self, t)
	action(self, t)
	local shield = self:hasShield() or self
	self:useEnergy(game.energy_to_act * self:combatSpeed(shield.special_combat))
	return true
end
block.speed = function(self, t)
	local shield = table.get(self:hasShield() or self, 'special_combat')
	if shield then return self:combatSpeed(shield) end
	return 1
end
block.display_speed = function(self, t)
	return ('Shield (#LIGHT_GREEN#%d%%#LAST# of a turn)'):format(100 * get(t.speed, self, t))
end
