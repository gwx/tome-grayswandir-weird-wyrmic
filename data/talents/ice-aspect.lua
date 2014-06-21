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


local dd = Talents.damDesc
local map = require 'engine.Map'
local damage_type = require 'engine.DamageType'
local particles = require 'engine.Particles'

newTalentType {
	type = 'wild-gift/ice-aspect',
	name = 'Ice Aspect',
	description = 'Channel the stalwart might of the ice drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Flashfreeze', short_name = 'WEIRD_FLASHFREEZE',
	type = {'wild-gift/ice-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 5,
	cooldown = function(self, t)
		local cd = 14
		if self:knowTalent('T_WEIRD_ICE_ASPECT') then
			cd = cd - self:callTalent('T_WEIRD_ICE_ASPECT', 'cooldown_reduce')
		end
		return cd
	end,
	damage = function(self, t) return self:wwScale {min = 1.0, max = 1.6, talent = t,} end,
	range = 0,
	radius = 1,
	duration = function(self, t) return self:wwScale {min = 2, max = 6, talent = t,} end,
	max_stacks = function(self, t)
		local stacks = 5
		if self:knowTalent('T_WEIRD_RIGID_BODY') then
			stacks = stacks + self:callTalent('T_WEIRD_RIGID_BODY', 'max_stacks')
		end
		return math.floor(stacks)
	end,
	combat_armor = function(self, t) return self:wwScale {
			min = 2, max = 5, talent = t, stat = 'str',}
	end,
	retaliation = function(self, t) return self:wwScale {
			min = 2, max = 7, talent = t, stat = 'wil', scale = 'combat',}
	end,
	tactical = {ATTACKAREA = 2,},
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t)}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)

		local damage = util.getval(t.damage, self, t)
		local duration = util.getval(t.duration, self, t)
		local hits = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			if self:attackTarget(actor, nil, damage, true) then
				if actor:canBe('pin') then
					actor:setEffect('EFF_FROZEN_FEET', duration, {src = self,})
				end
				hits = hits + 1
			end
		end
		self:project(tg, self.x, self.y, projector)

		self:setEffect('EFF_WEIRD_FROZEN_ARMOUR', 1, {
										 max_stacks = util.getval(t.max_stacks, self, t),
										 stacks = hits + 1,
										 retaliation = util.getval(t.retaliation, self, t),
										 combat_armor = util.getval(t.combat_armor, self, t),})

		return true
	end,
	info = function(self, t)
		return ([[Hit every adjacent enemy with your weapon for %d%% damage. If you hit, attempt to freeze their legs in place #SLATE#[phys vs. phys, pin]#LAST# for %d turns. You will then get the #LIGHT_BLUE#Frozen Armour#LAST# buff with 1 stack, plus an additional stack for every enemy hit, up to your maximum.

#LIGHT_BLUE#Frozen Armour#LAST# currently gives you %.1f #SLATE#[str]#LAST# armour and %.1f #SLATE#[wil]#LAST# cold retaliation damage for each stack. You may currently have up to %d stacks.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.duration, self, t),
							util.getval(t.combat_armor, self, t),
							dd(self, 'COLD', util.getval(t.retaliation, self, t)),
							util.getval(t.max_stacks, self, t))
	end,}

newTalent {
	name = 'Shattering Smash', short_name = 'WEIRD_SHATTERING_SMASH',
	type = {'wild-gift/ice-aspect', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 8,
	range = 1,
	cooldown = function(self, t)
		return self:wwScale {min = 9, max = 7, limit = 5, talent = t,}
	end,
	damage = function(self, t) return self:wwScale {min = 1.2, max = 1.8, talent = t,} end,
	shatter = function(self, t) return self:wwScale {min = 1.9, max = 3.4, talent = t,} end,
	knockback = function(self, t) return self:wwScale {min = 2, max = 9, stat = 'str',} end,
	wet = function(self, t) return self:wwScale {min = 2, max = 5, stat = 'wil',} end,
	tactical = {ATTACKAREA = 2, KNOCKBACK = 1,},
	target = function(self, t)
		return {type = 'hit', talent = t, range = util.getval(t.range, self, t),}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		if actor:attr('frozen') then
			if actor:hasEffect('EFF_FROZEN') then
				actor:removeEffect('EFF_FROZEN', true, true)
			elseif actor:hasEffect('EFF_FROZEN_FEET') then
				actor:removeEffect('EFF_FROZEN_FEET', true, true)
			end
			local damage = util.getval(t.shatter, self, t)
			if self:attackTarget(actor, nil, damage, true) then
				game.logSeen(self, '%s shatters the frozen %s!', self.name:capitalize(), actor.name)
				actor:setEffect('EFF_WET', util.getval(t.wet, self, t), {})
			end
		else
			local damage = util.getval(t.damage, self, t)
			if self:attackTarget(actor, nil, damage, true) then
				game.logSeen(self, '%s tries to #LIGHT_UMBER#knock back#LAST# %s!', self.name:capitalize(), actor.name)
				if actor:canBe 'knockback' and
					self:checkHit(self:combatPhysicalpower(), actor:combatPhysicalResist())
				then
					actor:knockback(self.x, self.y, util.getval(t.knockback, self, t))
					game.logSeen(self, '%s is #LIGHT_UMBER#knocked back#LAST#!', actor.name:capitalize())
				else
					game.logSeen(self, '%s resists the #LIGHT_UMBER#knock back#LAST#!', actor.name:capitalize())
				end
			end
		end
		game:playSoundNear(self, 'talents/ice')

		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent enemy with your weapon for %d%% damage and #LIGHT_UMBER#knocking it back#LAST# #SLATE#[phys vs phys, knockback]#LAST# %d #SLATE#[str]#LAST# tiles. If the target is #LIGHT_BLUE#frozen#LAST# or has #LIGHT_BLUE#frozen feet#LAST#, instead remove that effect, hit for %d%% weapon damage and inflict the #BLUE#wet#LAST# condition for %d #SLATE#[wil]#LAST# turns.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.knockback, self, t),
							util.getval(t.shatter, self, t) * 100,
							util.getval(t.wet, self, t))
	end,}

newTalent {
	name = 'Rigid Body', short_name = 'WEIRD_RIGID_BODY',
	type = {'wild-gift/ice-aspect', 3,},
	require = make_require(3),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	sustain_equilibrium = 20,
	equilibrium_cost = function(self, t)
		return self:wwScale {min = 4, max = 1, stat = 'str', round = 'ceil',}
	end,
	retaliation_percent = function(self, t)
		return self:wwScale {min = 0.5, max = 2.5, talent = t, stat = 'wil',}
	end,
	duration = function(self, t)
		return self:wwScale {min = 3, max = 6, stat = 'wil',}
	end,
	max_stacks = function(self, t)
		return self:wwScale {min = 0, max = 3, talent = t,}
	end,
	combat_def = function(self, t)
		return self:wwScale {min = 5, max = 40, stat = 'str', talent = t,}
	end,
	tactical = {BUFF = 2,},
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'frozen_armour_bonuses', {
																combat_def = util.getval(t.combat_def, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_STR then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[This will passively enhance your #LIGHT_BLUE#Frozen Armour#LAST#. It will increase the maximum number of stacks by %d, and make it give you %d #SLATE#[str]#LAST# defense as well. Whenever you take life damage, you have a chance equal to %.2f #SLATE#[wil]#LAST# times the percentage of max life you lost to attempt to freeze the source of the damage #SLATE#[mind vs phys]#LAST#.
While active, whenever your #LIGHT_BLUE#Frozen Armour#LAST# is up and you have not moved for a full turn, your equilibrium will increase by %d #SLATE#[str]#LAST# and your #LIGHT_BLUE#Frozen Armour#LAST# will be gain 1 stack, provided you pass an equilibrium check.]])
			:format(util.getval(t.max_stacks, self, t),
							util.getval(t.combat_def, self, t),
							util.getval(t.retaliation_percent, self, t),
							util.getval(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Ice Aspect', short_name = 'WEIRD_ICE_ASPECT',
	type = {'wild-gift/ice-aspect', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	inc_damage = function(self, t)
		return self:wwScale {min = 5, max = 35, talent = t, stat = 'str',}
	end,
	resists_pen = function(self, t)
		return self:wwScale {min = 3, max = 10, talent = t,}
	end,
	equilibrium_gain = function(self, t)
		return self:wwScale {min = 0.2, max = 2, talent = t,}
	end,
	cooldown_reduce = function(self, t)
		return self:wwScale {min = 0, max = 3, talent = t, round = 'floor',}
	end,
	passives = function(self, t, p)
		self:effectTemporaryValue(
			p, 'equilibrium_on_damage', {COLD = util.getval(t.equilibrium_gain, self, t),})
		self:effectTemporaryValue(
			p, 'inc_damage', {COLD = util.getval(t.inc_damage, self, t),})
		self:effectTemporaryValue(
			p, 'resists_pen', {COLD = util.getval(t.resists_pen, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_STR then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate ice as a dragon would. You gain %d%% #SLATE#[str]#LAST# to all #1133F3#cold#LAST# damage done, and %d%% #1133F3#cold#LAST# resistance piercing. You regain %.1f equilibrium on any turn in which you deal #1133F3#cold#LAST# damage.
This also reduces the cooldown of Flashfreeze by %d.
Points in this talent count double for the purposes of draconic form talents.]])
			:format(util.getval(t.inc_damage, self, t),
							util.getval(t.resists_pen, self, t),
							util.getval(t.equilibrium_gain, self, t),
							util.getval(t.cooldown_reduce, self, t))
	end,}

newTalent {
	name = 'Ice Claw', short_name = 'WEIRD_ICE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 5,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_CLAW', 'shared_cooldown')
	end,
	damage = function(self, t) return self:wwScale {min = 1.0, max = 1.8, talent = t,} end,
	duration = function(self, t) return self:wwScale {min = 1, max = 2, limit = 3, talent = t,} end,
	requires_target = true,
	tactical = {ATTACK = 2, DISABLE = 1,},
	range = 1,
	target = function(self, t)
		return {type = 'hit', talent = t, range = util.getval(t.range, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local damage = util.getval(t.damage, self, t)
		local duration = util.getval(t.duration, self, t)
		if self:attackTarget(actor, 'COLD', damage, true) then
			if actor:canBe('stun') then
				actor:setEffect('EFF_FROZEN', duration, {apply_power = self:combatPhysicalpower(),})
			end
			game:playSoundNear(self, 'talents/ice')
		end

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% weapon #1133F3#cold#LAST# damage, and attempt to #LIGHT_BLUE#freeze#LAST# #SLATE#[phys vs. phys, stun]#LAST# them for %d turns.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Ice Drake Aura', short_name = 'WEIRD_ICE_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 14,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_AURA', 'shared_cooldown')
	end,
	tactical = {ATTACKAREA = 2,},
	range = 0,
	radius = function(self, t) return self:wwScale {min = 2, max = 4, talent = t,} end,
	damage = function(self, t)
		return self:wwScale {
			min = 7, max = 40, talent = t, stat = 'str', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 3, max = 7, stat = 'str',} end,
	slow = function(self, t)
		return self:wwScale {min = 0.1, max = 0.3, limit = 0.5, talent = t, stat = 'wil',}
	end,
	slow_dur = function(self, t) return self:wwScale {min = 2, max = 7, talent = t, round = 'floor',} end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)

		local radius = util.getval(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_ice', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/ice')

		local damage = util.getval(t.damage, self, t)
		local duration = util.getval(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration, 'COLD', damage,
			radius, 5, nil, {type = 'ice_vapour',}, nil, 0, 0)
		effect.name = ('%s\'s ice aura'):format(self.name:capitalize())

		local slow = util.getval(t.slow, self, t)
		local slow_dur = util.getval(t.slow_dur, self, t)
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			actor:setEffect('EFF_SLOW', slow_dur, {power = slow,})
		end
		self:project(tg, self.x, self.y, projector)
		game:playSoundNear(self, 'talents/ice')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Chill the air around you in radius %d, dealing %d #SLATE#[str]#LAST# #1133F3#cold#LAST# damage for %d #SLATE#[str]#LAST# turns. Each enemy standing on one of these tiles will be #YELLOW#slowed#LAST# #SLATE#[phys vs phys]#LAST#, losing %d%% #SLATE#[wil]#LAST# global speed for %d turns.]])
			:format(util.getval(t.radius, self, t),
							dd(self, 'COLD', util.getval(t.damage, self, t)),
							util.getval(t.duration, self, t),
							util.getval(t.slow, self ,t) * 100,
							util.getval(t.slow_dur, self ,t))
	end,}

newTalent {
	name = 'Ice Breath', short_name = 'WEIRD_ICE_BREATH',
	type = {'wild-gift/draconic-breath', 1,}, hide = true,
	points = 5,
	equilibrium = 12,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_BREATH', 'shared_cooldown')
	end,
	tactical = {ATTACKAREA = 2,},
	range = 0,
	direct_hit = true,
	radius = function(self, t) return self:wwScale {min = 5, max = 9, talent = t,} end,
	damage = function(self, t)
		return self:wwScale {
			min = 35, max = 350, talent = t, stat = 'str', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 3, max = 7, stat = 'str',} end,
	slow = function(self, t) return self:wwScale {min = 0.05, max = 0.35, stat = 'str',} end,
	target = function(self, t)
		return {type = 'cone', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end

		local damage = self:mindCrit(util.getval(t.damage, self, t))
		local duration = util.getval(t.duration, self, t)
		local slow = util.getval(t.slow, self, t)
		local armor = self:hasEffect('EFF_WEIRD_FROZEN_ARMOUR')
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			damage_type:get('COLD').projector(self, x, y, 'COLD', damage)

			if actor.dead then
				kills = kills + 1
				return
			end

			if actor:hasEffect('EFF_FROZEN') then return end

			if actor:canBe('stun') then
				actor:setEffect('EFF_FROZEN', duration, {apply_power = self:combatPhysicalpower(),})
			end

			if not actor:hasEffect('EFF_FROZEN') then
				actor:setEffect('EFF_SLOW', duration, {power = slow,})
			end
		end
		self:project(tg, x, y, projector)

		if kills > 0 and armor then
			self:callEffect('EFF_WEIRD_FROZEN_ARMOUR', 'add_stacks', kills)
		end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_cold', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img='icewings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Breathe ice at your foes, doing %d #SLATE#[str]#LAST# #1133F3#cold#LAST# damage #SLATE#[mind crit]#LAST# in a radius %d cone. It will try to #LIGHT_BLUE#freeze#LAST# #SLATE#[phys vs. phys, stun]#LAST# anything not already #LIGHT_BLUE#frozen#LAST# for %d #SLATE#[str]#LAST# turns. If that fails, it will instead #YELLOW#slow#LAST# them by %d%% #SLATE#[str]#LAST# for the same amount of time.
Every enemy killed in the initial blast will give you 1 stack of #LIGHT_BLUE#Frozen Armour#LAST#, if you already have it.]])
			:format(dd(self, 'COLD', util.getval(t.damage, self, t)),
							util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							util.getval(t.slow, self, t) * 100)
	end,}
