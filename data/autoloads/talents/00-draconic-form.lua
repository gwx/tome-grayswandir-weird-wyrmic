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


local damage_type = require 'engine.DamageType'
local get = util.getval

newTalentType {
	type = 'wild-gift/draconic-form',
	name = 'Draconic Form',
	description = 'As your mind becomes closer to the draconic ideal, your body does likewise.',
	allow_random = true,}

newTalentType {
	type = 'wild-gift/draconic-claw',
	name = 'Draconic Claw',
	description = 'Draconic Claw Strikes',
	speed = 'weapon',}

newTalentType {
	type = 'wild-gift/draconic-aura',
	name = 'Draconic Aura',
	description = 'Draconic Auras',
	is_mind = true,}

newTalentType {
	type = 'wild-gift/draconic-breath',
	name = 'Draconic Breath',
	description = 'Draconic Breaths',
	is_mind = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

local get_element_points = function(self, element)
	local points = 0
	local typ = self:getTalentTypeFrom('wild-gift/'..element..'-aspect')
	for i = 1, 3 do
		points = points + self:getTalentLevelRaw(typ.talents[i])
	end
	points = points + self:getTalentLevelRaw(typ.talents[4]) * 2
	return self:scale {low = 0, high = 25, points * 4,}
end

local elements = {
	fire = 'FIRE',
	ice = 'COLD',
	lightning = 'LIGHTNING',
	sand = 'PHYSICAL',
	blade = {text_color = '#CCCCCC#', immunity = 'cut', immunity_display = 'bleed',},
	stone = {text_color = '#AA8833#', immunity = 'knockback', immunity_display = 'knockback',},}

local known_elements = function(self)
	local elements = {}
	if self:knowTalentType 'wild-gift/fire-aspect' then table.insert(elements, 'fire') end
	if self:knowTalentType 'wild-gift/ice-aspect' then table.insert(elements, 'ice') end
	if self:knowTalentType 'wild-gift/lightning-aspect' then table.insert(elements, 'lightning') end
	if self:knowTalentType 'wild-gift/sand-aspect' then table.insert(elements, 'sand') end
	if self:knowTalentType 'wild-gift/blade-aspect' then table.insert(elements, 'blade') end
	if self:knowTalentType 'wild-gift/stone-aspect' then table.insert(elements, 'stone') end
	return elements
end

local get_element_level = function(self, t, element, threshold)
	local base_level = self:getTalentLevel(t)
	if base_level == 0 then return nil, 1 end
	local power = base_level * 2.5
	local epower = get_element_points(self, element) * 1.5
	power = power + epower
	if power < threshold then
		local missing = (threshold - power) / 1.5
		if epower == 0 then missing = math.max(1, missing) end
		return nil, missing
	elseif epower == 0 then
		return nil, 1
	else
		power = math.ceil(power - threshold) * 0.5
		local typ = self:getTalentTypeFrom('wild-gift/'..element..'-aspect')
		power = math.min(3.5, power - base_level * 0.5) * self:getTalentTypeMastery(typ) + base_level * 0.5
		return math.floor(power)
	end
end

local on_learn_claw = function(self, t)
	local threshold = get(t.threshold, self, t)
	for _, element in ipairs(known_elements(self)) do
		local claw = 'T_WEIRD_'..element:upper()..'_CLAW'
		local level = get_element_level(self, t, element, threshold) or 0
		while self:getTalentLevelRaw(claw) < level do
			self:learnTalent(claw, true)
		end
		while self:getTalentLevelRaw(claw) > level do
			self:unlearnTalent(claw)
		end
	end
end

newTalent {
	name = 'Draconic Claws', short_name = 'WEIRD_DRACONIC_CLAW',
	type = {'wild-gift/draconic-form', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	auto_relearn_passive = true,
	combat_physcrit = function(self, t)
		return self:scale {low = 4, high = 11, t,}
	end,
	shared_cooldown = function(self, t)
		return self:scale {low = 10, high = 4.5, limit = 2, t, after = 'floor',}
	end,
	threshold = 10,
	passives = function(self, t, p)
		self:talentTemporaryValue(
			p, 'combat_physcrit', get(t.combat_physcrit, self, t))
		on_learn_claw(self, t)
	end,
	on_unlearn = on_learn_claw,
	info = function(self, t)
		local threshold = get(t.threshold, self, t)
		local msg = ''
		for _, element in ipairs(known_elements(self)) do
			local typ = elements[element]
			if type(typ) == 'string' then typ = damage_type:get(typ) end
			local color = typ.text_color or '#WHITE#'
			local part = ('%s%s#LAST# '):format(color, element:capitalize()..' Claw: ')
			local level, needed = get_element_level(self, t, element, threshold)
			part = part .. ('Level %d'):format(level or 0)
			part = part .. ('   #SLATE#<Need %s more points.>#WHITE#'):format(
				needed and ('%.1f'):format(needed) or 'no')
			msg = msg .. part .. '\n'
		end
		return ([[You have learned to emulate the aggressive nature of dragons, increasing your physical critical chance by %d%% #SLATE#[*]#LAST#.

You will also learn the following talents. They will all have a shared cooldown of %d #SLATE#[*]#LAST# :
%s]])
			:format(get(t.combat_physcrit, self, t),
							get(t.shared_cooldown, self, t),
							msg)
	end,}

newTalent {
	name = 'Draconic Scales', short_name = 'WEIRD_DRACONIC_SCALES',
	type = {'wild-gift/draconic-form', 2,},
	require = make_require(2),
	points = 5,
	mode = 'passive',
	resists = function(self, t) return self:scale {low = 0.3, high = 1.2, t,} end,
	combat_armor_hardiness = function(self, t) return self:scale {low = 0, high = 12, t,} end,
	combat_armor = function(self, t) return self:scale {low = 3, high = 30, t, 'con',} end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_CON then self:updateTalentPassives(t) end
	end,
	passives = function(self, t, p)
		local resists = {}
		local resist_mult = get(t.resists, self, t)
		for _, element in ipairs(known_elements(self)) do
			local typ = elements[element]
			if type(typ) == 'string' then
				local mult = 1
				if typ == 'PHYSICAL' then mult = 0.6 end
				resists[typ] = resist_mult * get_element_points(self, element) * mult
			else
				self:talentTemporaryValue(
					p, typ.immunity..'_immune',
					resist_mult * get_element_points(self, element) * 0.01)
			end
		end
		self:talentTemporaryValue(p, 'resists', resists)
		self:talentTemporaryValue(
			p, 'combat_armor', get(t.combat_armor, self, t))
		self:talentTemporaryValue(
			p, 'combat_armor_hardiness', get(t.combat_armor_hardiness, self, t))
	end,
	info = function(self, t)
		local msg = ''
		local resist_mult = get(t.resists, self, t)
		for _, element in ipairs(known_elements(self)) do
			local typ = elements[element]
			local name
			local mult = 1
			if typ == 'PHYSICAL' then mult = 0.6 end
			if type(typ) == 'string' then
				local tt = typ
				typ = damage_type:get(typ)
				name = tt:lower():capitalize()
			else
				name = typ.immunity_display:lower():capitalize()
			end
			local color = typ.text_color or '#WHITE#'
			local amount = resist_mult * (get_element_points(self, element) or 0) * mult
			msg = msg .. ('%s%s#WHITE# +%.1f%%\n'):format(color, name..': ', amount)
		end
		return ([[Your body has hardened, giving you %d #SLATE#[*, con]#LAST# armour and %d%% #SLATE#[*]#LAST# hardiness.
You will also get the following resists / immunities based on your elemental talents:
%s]])
			:format(get(t.combat_armor, self, t),
							get(t.combat_armor_hardiness, self, t),
							msg)
	end,}

local on_learn_aura = function(self, t)
	local threshold = get(t.threshold, self, t)
	for _, element in ipairs(known_elements(self)) do
		local aura = 'T_WEIRD_'..element:upper()..'_AURA'
		local level = get_element_level(self, t, element, threshold) or 0
		while self:getTalentLevelRaw(aura) < level do
			self:learnTalent(aura, true)
		end
		while self:getTalentLevelRaw(aura) > level do
			self:unlearnTalent(aura)
		end
	end
end

newTalent {
	name = 'Draconic Aura', short_name = 'WEIRD_DRACONIC_AURA',
	type = {'wild-gift/draconic-form', 3,},
	require = make_require(3),
	points = 5,
	mode = 'passive',
	knockback_immune = function(self, t)
		return self:scale {low = 0.10, high = 0.40, t,}
	end,
	pin_immune = function(self, t)
		return self:scale {low = 0.10, high = 0.30, t,}
	end,
	fear_immune = function(self, t)
		return self:scale {low = 0.10, high = 0.20, t,}
	end,
	shared_cooldown = function(self, t)
		return self:scale {low = 18, high = 9, limit = 5, t, after = 'floor',}
	end,
	threshold = 16,
	auto_relearn_passive = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(
			p, 'knockback_immune', get(t.knockback_immune, self, t))
		self:talentTemporaryValue(
			p, 'pin_immune', get(t.pin_immune, self, t))
		self:talentTemporaryValue(
			p, 'fear_immune', get(t.fear_immune, self, t))
		on_learn_aura(self, t)
	end,
	on_unlearn = on_learn_aura,
	info = function(self, t)
		local threshold = get(t.threshold, self, t)
		local msg = ''
		for _, element in ipairs(known_elements(self)) do
			local typ = elements[element]
			if type(typ) == 'string' then typ = damage_type:get(typ) end
			local color = typ.text_color or '#WHITE#'
			local part = ('%s%-18s#LAST# '):format(color, element:capitalize()..' Drake Aura:')
			local level, needed = get_element_level(self, t, element, threshold)
			part = part .. ('Level %d'):format(level or 0)
			part = part .. ('   #SLATE#<Need %s more points.>#WHITE#'):format(
				needed and ('%.1f'):format(needed) or 'no')
			msg = msg .. part .. '\n'
		end
		return ([[You have learned to emulate the proud bearing and aura of dragons, increasing your knockback immunity by %d%% #SLATE#[*]#LAST#, your pin immunity by %d%% #SLATE#[*]#LAST#, and your fear immunity by %d%% #SLATE#[*]#LAST#.

You will also learn the following talents. They will all have a shared cooldown of %d #SLATE#[*]#LAST# :
%s]])
			:format(get(t.knockback_immune, self, t) * 100,
							get(t.pin_immune, self, t) * 100,
							get(t.fear_immune, self, t) * 100,
							get(t.shared_cooldown, self, t),
							msg)
	end,}

local on_learn_breath = function(self, t)
	local threshold = get(t.threshold, self, t)
	for _, element in ipairs(known_elements(self)) do
		local breath = 'T_WEIRD_'..element:upper()..'_BREATH'
		local level = get_element_level(self, t, element, threshold) or 0
		while self:getTalentLevelRaw(breath) < level do
			self:learnTalent(breath, true)
		end
		while self:getTalentLevelRaw(breath) > level do
			self:unlearnTalent(breath)
		end
	end
end

newTalent {
	name = 'Draconic Breath', short_name = 'WEIRD_DRACONIC_BREATH',
	type = {'wild-gift/draconic-form', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	shared_cooldown = function(self, t)
		return self:scale {low = 24, high = 12, limit = 8, t, after = 'floor',}
	end,
	max_life = function(self, t)
		return self:scale {low = 20, high = 120, t, 'con',}
	end,
	life_regen = function(self, t)
		return self:scale {low = 0, high = 4, t, 'con',}
	end,
	healing_factor = function(self, t)
		return self:scale {low = 0, high = 0.4, t, 'con',}
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_CON then self:updateTalentPassives(t) end
	end,
	threshold = 21,
	auto_relearn_passive = true,
	passives = function(self, t, p)
		self:talentTemporaryValue(
			p, 'max_life', get(t.max_life, self, t))
		self:talentTemporaryValue(
			p, 'life_regen', get(t.life_regen, self, t))
		self:talentTemporaryValue(
			p, 'healing_factor', get(t.healing_factor, self, t))
		on_learn_breath(self, t)
	end,
	on_unlearn = on_learn_breath,
	info = function(self, t)
		local threshold = get(t.threshold, self, t)
		local msg = ''
		for _, element in ipairs(known_elements(self)) do
			local typ = elements[element]
			if type(typ) == 'string' then typ = damage_type:get(typ) end
			local color = typ.text_color or '#WHITE#'
			local part = ('%s%-14s#LAST# '):format(color, element:capitalize()..' Breath:')
			local level, needed = get_element_level(self, t, element, threshold)
			part = part .. ('Level %d'):format(level or 0)
			part = part .. ('   #SLATE#<Need %s more points.>#WHITE#'):format(
				needed and ('%.1f'):format(needed) or 'no')
			msg = msg .. part .. '\n'
		end
		return ([[Your great endurance and stamina at last allow you the dragon's most fearsome weapon, their breaths. This passively gives you %d #SLATE#[*, con]#LAST# max life, %.1f #SLATE#[*, con]#LAST# life regen and %d%% #SLATE#[*, con]#LAST# healing factor.

You will also learn the following talents. They will all have a shared cooldown of %d #SLATE#[*]#LAST#:
%s]])
			:format(get(t.max_life, self, t),
							get(t.life_regen, self, t),
							get(t.healing_factor, self, t) * 100,
							get(t.shared_cooldown, self, t),
							msg)
	end,}
