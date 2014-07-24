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
local get = util.getval

newTalentType {
	type = 'wild-gift/ice-aspect',
	name = 'Ice Aspect',
	description = 'Channel the stalwart might of the ice drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Flashfreeze', short_name = 'WEIRD_FLASHFREEZE',
	type = {'wild-gift/ice-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 5,
	cooldown = 12,
	no_energy = 'fake',
	weapon_mult = function(self, t) return self:scale {low = 1, high = 1.6, t,} end,
	range = 0,
	radius = 1,
	duration = function(self, t) return self:scale {low = 2, high = 6, t,} end,
	max_stacks = function(self, t)
		local stacks = 5
		if self:knowTalent 'T_WEIRD_RIGID_BODY' then
			stacks = stacks + self:callTalent('T_WEIRD_RIGID_BODY', 'max_stacks')
		end
		return math.floor(stacks)
	end,
	combat_armor = function(self, t)
		return self:scale {low = 2, high = 5, t, 'mind',}
	end,
	retaliation = function(self, t)
		return self:scale {low = 2, high = 7, t, 'mind',}
	end,
	tactical = {ATTACKAREA = 2,},
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t)}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local weapon_mult = get(t.weapon_mult, self, t)
		local duration = get(t.duration, self, t)
		local hits = 0
		local use_energy = false -- get a single hit to determine combat speed.
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			if self:attackTarget(actor, nil, weapon_mult, use_energy) then
				if actor:canBe 'pin' then
					actor:setEffect('EFF_FROZEN_FEET', duration, {src = self,})
				end
				hits = hits + 1
			end
			use_energy = true
		end
		self:project(tg, self.x, self.y, projector)

		if not use_energy then self:useEnergy() end  -- Use standard speed if we didn't make any attacks.

		local max_stacks = get(t.max_stacks, self, t)
		local stacks = math.min(max_stacks, hits + 1)
		local eff = {
			stacks = stacks,
			max_stacks = max_stacks,
			combat_armor = get(t.combat_armor, self, t),
			on_melee_hit = get(t.retaliation, self, t),}
		self:setEffect('EFF_WEIRD_FROZEN_ARMOUR', 1, eff)

		return true
	end,
	info = function(self, t)
		return ([[Hit every adjacent enemy with your weapon for %d%% damage. If you hit, attempt to freeze their legs in place #SLATE#[phys vs. phys, pin]#LAST# for %d turns. You will then get the #LIGHT_BLUE#Frozen Armour#LAST# buff with 1 stack, plus an additional stack for every enemy hit, up to your maximum.

#LIGHT_BLUE#Frozen Armour#LAST# currently gives you %.1f #SLATE#[*, mind]#LAST# armour and %.1f #SLATE#[*, mind]#LAST# cold retaliation damage for each stack. You may currently have up to %d stacks.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.duration, self, t),
							get(t.combat_armor, self, t),
							dd(self, 'COLD', get(t.retaliation, self, t)),
							get(t.max_stacks, self, t))
	end,}

newTalent {
	name = 'Shattering Smash', short_name = 'WEIRD_SHATTERING_SMASH',
	type = {'wild-gift/ice-aspect', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 8,
	range = 1,
	cooldown = 8,
	no_energy = 'fake',
	weapon_mult_normal = function(self, t) return self:scale {low = 1.2, high = 1.8, t,} end,
	weapon_mult_shatter = function(self, t) return self:scale {low = 1.2, high = 2.7, t,} end,
	knockback = function(self, t) return self:scale {low = 3, high = 7, 'phys',} end,
	wet_duration = function(self, t) return self:scale {low = 3, high = 8, t, after = 'floor',} end,
	tactical = {ATTACK = 2, KNOCKBACK = 1,},
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		if actor:attr('frozen') then
			if actor:hasEffect('EFF_FROZEN') then
				actor:removeEffect('EFF_FROZEN', true, true)
			elseif actor:hasEffect('EFF_FROZEN_FEET') then
				actor:removeEffect('EFF_FROZEN_FEET', true, true)
			end
			local weapon_mult = get(t.weapon_mult_shatter, self, t)
			if self:attackTarget(actor, nil, weapon_mult) then
				game.logSeen(self, '%s shatters the frozen %s!', self.name:capitalize(), actor.name)
				actor:setEffect('EFF_WET', get(t.wet_duration, self, t), {})
			end
		else
			local weapon_mult = get(t.weapon_mult_normal, self, t)
			if self:attackTarget(actor, nil, weapon_mult) then
				game.logSeen(self, '%s tries to #LIGHT_UMBER#knock back#LAST# %s!', self.name:capitalize(), actor.name)
				if actor:canBe 'knockback' and
					self:checkHit(self:combatPhysicalpower(), actor:combatPhysicalResist())
				then
					actor:knockback(self.x, self.y, get(t.knockback, self, t))
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
		return ([[Hit an adjacent enemy with your weapon for %d%% #SLATE#[*]#LAST# damage and #LIGHT_UMBER#knocking it back#LAST# #SLATE#[phys vs phys, knockback]#LAST# %d #SLATE#[phys]#LAST# tiles. If the target is #LIGHT_BLUE#frozen#LAST# or has #LIGHT_BLUE#frozen feet#LAST#, instead remove that effect, hit for %d%% #SLATE#[*]#LAST# weapon damage and inflict the #1133F3#wet#LAST# condition for %d #SLATE#[*]#LAST# turns.]])
			:format(get(t.weapon_mult_normal, self, t) * 100,
							get(t.knockback, self, t),
							get(t.weapon_mult_shatter, self, t) * 100,
							get(t.wet_duration, self, t))
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
	equilibrium_cost = function(self, t) return self:scale {low = 5, high = 2, limit = 1, t,} end,
	retaliation_percent = function(self, t) return self:scale {low = 0.5, high = 2.0, t,} end,
	duration = 4,
	max_stacks = function(self, t)
		return self:scale {low = 0, high = 3, t, after = 'floor',}
	end,
	tactical = {BUFF = 2,},
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[This will passively enhance your #LIGHT_BLUE#Frozen Armour#LAST#. It will increase the maximum number of stacks by %d #SLATE#[*]#LAST#. Whenever you take life damage, you have a chance equal to %.2f #SLATE#[*]#LAST# times the percentage of max life you lost to attempt to #LIGHT_BULE#Freeze#LAST# the source of the damage #SLATE#[mind vs phys, stun]#LAST#.
While active, whenever your #LIGHT_BLUE#Frozen Armour#LAST# is up and you have not moved for a full turn, your #00FF74#equilibrium#LAST# will increase by %d #SLATE#[*]#LAST# and your #LIGHT_BLUE#Frozen Armour#LAST# will be gain 1 stack, provided you pass an #00FF74#equilibrium#LAST# check.]])
			:format(get(t.max_stacks, self, t),
							get(t.retaliation_percent, self, t),
							get(t.equilibrium_cost, self, t))
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
		return self:scale {low = 5, high = 25,}
	end,
	resists_pen = function(self, t)
		return self:scale {low = 0, high = 12, t,}
	end,
	equilibrium_gain = function(self, t)
		return self:scale {low = 0.2, high = 2, t,}
	end,
	cooldown_mod = function(self, t)
		return self:scale {low = 100, high = 60, limit = 33, t}
	end,
	passives = function(self, t, p)
		self:autoTemporaryValues(
			p, {
				equilibrium_on_damage = {COLD = get(t.equilibrium_gain, self, t),},
				inc_damage = {COLD = get(t.inc_damage, self, t),},
				resists_pen = {COLD = get(t.resists_pen, self, t),},})
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate ice as a dragon would. You gain %d%% #SLATE#[*]#LAST# to all #1133F3#cold#LAST# damage done, and %d%% #SLATE#[*]#LAST# #1133F3#cold#LAST# resistance piercing. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you deal #1133F3#cold#LAST# damage.
Points in this talent count double for the purposes of draconic form talents. All of your ice aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_ICE_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_ICE_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Ice Claw', short_name = 'WEIRD_ICE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 5,
	no_energy = 'fake',
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_CLAW', 'shared_cooldown')
	end,
	group_cooldown = function(self, t)
		return aspect_cooldown(self, t, get(t.cooldown, self, t))
	end,
	set_group_cooldown = function(self, t, cd)
		self.talents_cd[t.id] =
			math.max(self.talents_cd[t.id] or 0, aspect_cooldown(self, t, cd))
	end,
	weapon_mult = function(self, t) return self:scale {low = 1.0, high = 1.8, t,} end,
	duration = 3,
	requires_target = true,
	tactical = {ATTACK = 2, DISABLE = 1,},
	range = 1,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local weapon_mult = get(t.weapon_mult, self, t)
		local duration = get(t.duration, self, t)
		if self:attackTarget(actor, 'COLD', weapon_mult) then
			if actor:canBe('stun') then
				actor:setEffect('EFF_FROZEN', duration, {apply_power = self:combatPhysicalpower(),})
			end
			game:playSoundNear(self, 'talents/ice')
		end

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% #SLATE#[*]#LAST# weapon #1133F3#cold#LAST# damage, and attempt to #LIGHT_BLUE#Freeze#LAST# #SLATE#[phys vs phys, stun]#LAST# them for %d turns.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Ice Drake Aura', short_name = 'WEIRD_ICE_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 14,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_AURA', 'shared_cooldown')
	end,
	group_cooldown = function(self, t)
		return aspect_cooldown(self, t, get(t.cooldown, self, t))
	end,
	set_group_cooldown = function(self, t, cd)
		self.talents_cd[t.id] =
			math.max(self.talents_cd[t.id] or 0, aspect_cooldown(self, t, cd))
	end,
	tactical = {ATTACKAREA = 2,},
	range = 0,
	is_mind = true,
	radius = function(self, t) return self:scale {low = 2, high = 5, limit = 8, t, after = 'floor',} end,
	damage = function(self, t)
		return self:scale {
			low = 7, high = 50, t, 'phys', after = 'damage',}
	end,
	duration = 6,
	slow = function(self, t)
		return self:scale {low = 0.1, high = 0.3, limit = 0.5, t,}
	end,
	slow_dur = 6,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local radius = get(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_ice', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/ice')

		local damage = get(t.damage, self, t)
		local duration = get(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration, 'COLD', damage,
			radius, 5, nil, {type = 'ice_vapour',}, nil, 0, 0)
		effect.name = ('%s\'s ice aura'):format(self.name:capitalize())

		local slow = get(t.slow, self, t)
		local slow_dur = get(t.slow_dur, self, t)
		local apply_power = self:combatMindpower()
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			actor:setEffect('EFF_SLOW', slow_dur, {
												power = slow,
												apply_power = apply_power})
		end
		self:project(tg, self.x, self.y, projector)
		game:playSoundNear(self, 'talents/ice')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Chill the air around you in radius %d #SLATE#[*]#LAST#, dealing %d #SLATE#[phys]#LAST# #1133F3#cold#LAST# damage for %d turns. Each enemy standing on one of these tiles will be #YELLOW#slowed#LAST# #SLATE#[mind vs phys]#LAST#, losing %d%% #SLATE#[*]#LAST# global speed for %d turns.]])
			:format(get(t.radius, self, t),
							dd(self, 'COLD', get(t.damage, self, t)),
							get(t.duration, self, t),
							get(t.slow, self ,t) * 100,
							get(t.slow_dur, self ,t))
	end,}

newTalent {
	name = 'Ice Breath', short_name = 'WEIRD_ICE_BREATH',
	type = {'wild-gift/draconic-breath', 1,}, hide = true,
	points = 5,
	equilibrium = 12,
	is_mind = true,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_BREATH', 'shared_cooldown')
	end,
	group_cooldown = function(self, t)
		return aspect_cooldown(self, t, get(t.cooldown, self, t))
	end,
	set_group_cooldown = function(self, t, cd)
		self.talents_cd[t.id] =
			math.max(self.talents_cd[t.id] or 0, aspect_cooldown(self, t, cd))
	end,
	tactical = {ATTACKAREA = 2,},
	range = 0,
	direct_hit = true,
	radius = function(self, t) return self:scale {low = 5, high = 8, limit = 10, t, after = 'ceil',} end,
	damage = function(self, t)
		return self:scale {low = 35, high = 350, t, 'phys', after = 'damage',}
	end,
	duration = 5,
	slow = function(self, t) return self:scale {low = 0.05, high = 0.35, limit = 0.5, 'mind',} end,
	target = function(self, t)
		return {type = 'cone', talent = t, selffire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end

		local damage = self:mindCrit(get(t.damage, self, t))
		local duration = get(t.duration, self, t)
		local slow = get(t.slow, self, t)
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			self:projectOn(actor, 'COLD', damage)

			if actor.dead then
				kills = kills + 1
				return
			end

			if actor:hasEffect 'EFF_FROZEN' then return end

			if actor:canBe 'stun' then
				actor:setEffect('EFF_FROZEN', duration, {apply_power = self:combatPhysicalpower(),})
			end

			if not actor:hasEffect('EFF_FROZEN') then
				actor:setEffect('EFF_SLOW', duration, {power = slow,})
			end
		end
		self:project(tg, x, y, projector)

		self:alterTalentCoolingdown('T_WEIRD_FLASHFREEZE', -kills)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_cold', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img='icewings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Breathe ice at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# #1133F3#cold#LAST# damage in a radius %d #SLATE#[*]#LAST# cone. It will try to #LIGHT_BLUE#freeze#LAST# #SLATE#[phys vs. phys, stun]#LAST# anything not already #LIGHT_BLUE#frozen#LAST# for %d turns. If that fails, it will instead #YELLOW#slow#LAST# them by %d%% #SLATE#[mind]#LAST# for the same amount of time.
Every enemy killed in the initial blast will reduce the cooldown of Flashfreeze by 1.]])
			:format(dd(self, 'COLD', get(t.damage, self, t)),
							get(t.radius, self, t),
							get(t.duration, self, t),
							get(t.slow, self, t) * 100)
	end,}
