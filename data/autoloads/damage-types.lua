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

local physical = DamageType.dam_def.PHYSICAL.projector
DamageType.dam_def.PHYSICAL.projector = function(src, x, y, type, dam)
	local actor = game.level.map(x, y, map.ACTOR)
	if not actor then return 0 end

	local temps = {}

	if src and src.autoTemporaryValues then
		local inc = src:attr 'inc_wound_damage'
		if inc then
			local wounds = #actor:filterTemporaryEffects(function(effect, parameters) return effect.subtype.wound end)
			if wounds > 0 then
				inc = inc * wounds
				src:autoTemporaryValues(
					temps, {
						inc_damage = {PHYSICAL = inc,},
						resists_pen = {PHYSICAL = inc,},})
			end
		end
	end

	local ret = {physical(src, x, y, type, dam)}

	if src and src.autoTemporaryValuesRemove then
		src:autoTemporaryValuesRemove(temps)
	end

	return unpack(ret)
end

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

local lightning = DamageType.dam_def.LIGHTNING.projector
DamageType.dam_def.LIGHTNING.projector = function(src, x, y, type, dam)
	if src and src.weird_lightning_daze and src.weird_lightning_daze > 0 then
		local map = require 'engine.Map'
		local actor = game.level.map(x, y, map.ACTOR)
		if actor and actor:canBe('stun') then
			local effect = {src = src,}
			if src.combatMindpower then
				effect.apply_power = src:combatMindpower()
			end
			actor:setEffect('EFF_DAZED', src.weird_lightning_daze, effect)
		end
	end
	return lightning(src, x, y, type, dam)
end

newDamageType {
	name = 'burrow', type = 'WEIRD_BURROW',
	projector = function(src, x, y, typ, dam)
		if game.level.map:dig(x, y, src) then
			if type(dam) ~= 'table' then dam = {dam = dam,} end
			src:incEquilibrium(dam.cost or 5)
			if src and
				src.equilibriumChance and not src:equilibriumChance() and
				src.isTalentActive and src:isTalentActive 'T_WEIRD_BURROW'
			then
				src:forceUseTalent('T_WEIRD_BURROW', {no_energy = true,})
			end
		end
	end,}

newDamageType {
	name = 'multihued', type = 'WEIRD_MULTIHUED', text_color = '#BBFFBB#',
	projector = function(src, x, y, typ, dam)
		typ = util.getval {'PHYSICAL', 'FIRE', 'COLD', 'LIGHTNING', 'ACID',}
		return DamageType:get(typ).projector(src, x, y, typ, dam)
	end,}
