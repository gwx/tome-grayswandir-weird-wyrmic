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
local stats = require 'engine.interface.ActorStats'
local particles = require 'engine.Particles'
local get = util.getval

newTalentType {
	type = 'wild-gift/stone-aspect',
	name = 'Stone Aspect',
	description = 'Channel the sturdy might of the stone drakes.',
	speed = 'shield',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

local shield_pre_use = function(self, t, silent)
	if not self:hasShield() and not self.innate_drake_talents then
		if not silent then
			game.logPlayer(self, 'You require a weapon and shield to use this talent.')
		end
		return false
	end
	return true
end

newTalent {
	name = 'Heavy Impact', short_name = 'WEIRD_HEAVY_IMPACT',
	type = {'wild-gift/stone-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 7,
	cooldown = 12,
	no_energy = 'fake',
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 2.0, high = 3.2, t,} end,
	stun = function(self, t) return {
			duration = get(t.stun_dur, self ,t),
			duration_scale = ' #SLATE#[*]#LAST#',}
	end,
	stun_dur = function(self, t) return self:scale {low = 3, high = 6, limit = 9, t, after = 'ceil',} end,
	tactical = {ATTACK = 2, DISABLE = 2, BUFF = 2,},
	requires_target = true,
	target = function(self, t) return {type = 'hit', talent = t, range = get(t.range, self, t),} end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	on_pre_use = shield_pre_use,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		self.talents_cd.T_BLOCK = nil
		self:forceUseTalent('T_BLOCK', {no_energy = true,})

		local shield = (self:hasShield() or self).special_combat -- for the actual drakes
		local weapon_mult = get(t.weapon_mult, self, t)
		local speed, hit = self:attackTargetWith(actor, shield, nil, weapon_mult)
		if hit then self:inflict('stun', actor, get(t.stun, self, t)) end

		self:useEnergy(speed * game.energy_to_act)

		return true
	end,
	info = function(self, t)
		return ([[Bash the target with your shield for %d%% #SLATE#[*]#LAST# damage, attempting to %s. You will then immediately begin Blocking.
Requires a weapon and shield to use.]])
			:format(get(t.weapon_mult, self, t) * 100,
							self:describeInflict('stun', nil, get(t.stun, self, t)))
	end,}

newTalent {
	name = 'Flesh of Stone', short_name = 'WEIRD_FLESH_OF_STONE',
	type = {'wild-gift/stone-aspect', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	sustain_equilibrium = 20,
	cooldown = 16,
	no_energy = true,
	range = 1,
	resists = function(self, t) return self:scale {low = 5, high = 20, limit = 30, t,} end,
	ignore_crit = function(self, t) return self:scale {low = 0, high = 30, limit = 50, t, 'con',} end,
	block_power_inc = function(self, t) return self:scale {low = 20, high = 150, limit = 250, t,} end,
	tactical = {BUFF = 2, ESCAPE = -2,},
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	on_pre_use = shield_pre_use,
	activate = function(self, t)
		local p = {}
		local resist = get(t.resists, self, t)
		self:autoTemporaryValues(
			p, {
				movement_speed = -0.5,
				resists = {FIRE = resist, LIGHTNING = resist, PHYSICAL = resist * 0.6,},
				block_power_inc = get(t.block_power_inc, self, t),
				stone_immune = 1,
				ignore_direct_crits = get(t.ignore_crit, self, t),})
		return p
	end,
	deactivate = function(self, t) return true end,
	info = function(self, t)
		local resist = get(t.resists, self, t)
		return ([[Turns your flesh partially to stone, reducing your movement speed by 50%%. You will become immune to being further petrified, gain %d%% #SLATE#[*]#LAST# #LIGHT_RED#fire#LAST# and #ROYAL_BLUE#lightning#LAST# resistance and %d%% #SLATE#[*]#LAST# physical resistance, and gain a %d%% #SLATE#[*, con]#LAST# chance to ignore critical hits. Your blocks will be %d%% #SLATE#[*]#LAST# as powerful.
Requires a weapon and shield to use.]])
			:format(resist, resist * 0.6,
							get(t.ignore_crit, self, t),
							100 + get(t.block_power_inc, self, t))
	end,}

newTalent {
	name = 'Cannonball', short_name = 'WEIRD_CANNONBALL',
	type = {'wild-gift/stone-aspect', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 8,
	no_energy = 'fake',
	cooldown = 18,
	range = function(self, t) return self:scale {low = 2, high = 3.5, limit = 4.5, t, after = 'floor',} end,
	weapon_mult = function(self, t) return self:scale {low = 1.7, high = 2.5, t,} end,
	radius = 3,
	offbalance = function(self, t) return self:scale {low = 2, high = 5, limit = 8, t, after = 'ceil',} end,
	daze = function(self, t) return {
			duration = get(t.daze_dur, self ,t),
			duration_scale = ' #SLATE#[*]#LAST#',}
	end,
	daze_dur = function(self, t) return self:scale {low = 2, high = 5, limit = 8, t, after = 'floor',} end,
	tactical = {ATTACK = 2, DISABLE = 2,},
	requires_target = true,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false, nowarning = true, nolock = true,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	on_pre_use = shield_pre_use,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end
		local no_move = x == self.x and y == self.y
		if not no_move and not self:canMove(x, y) then return end

		if not no_move then self:move(x, y, true) end

		local offbalance = get(t.offbalance, self, t)
		local projector = function(x, y)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			actor:setEffect('EFF_OFFBALANCE', offbalance, {src = self,})
		end
		self:project(tg, self.x, self.y, projector)

		game.level.map:particleEmitter(
			self.x, self.y, tg.radius, 'shout', {
				additive = true, life = 10, size = 3, distorion_factor = 0.5,
				radius = tg.radius, nb_circles = 8,
				rm = 0.8, rM = 1.0,
				gm = 0.0, gM = 0.0,
				bm = 0.1, bM = 0.2,
				am = 0.4, aM = 0.6,})

		local shield = (self:hasShield() or self).special_combat -- for the actual drakes
		local weapon_mult = get(t.weapon_mult, self, t)
		projector = function(x, y)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			local speed, hit = self:attackTargetWith(actor, shield, nil, weapon_mult)
			if hit then self:inflict('daze', actor, get(t.daze, self, t)) end
		end
		tg.radius = 1
		self:project(tg, self.x, self.y, projector)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'ball_earth', {radius = tg.radius,})

		game:playSoundNear(self, 'talents/earth')

		self:useEnergy(game.energy_to_act * self:combatSpeed(shield))

		return true
	end,
	info = function(self, t)
		return ([[Launch yourself into the air, coming down on a space up to %d #SLATE#[*]#LAST# tiles away, performing a %d%% #SLATE#[*]#LAST# damage shield bash on every adjacent enemy. Enemies hit will be %s.
In addition, you will knock everything within radius %d off balance #SLATE#[phys vs phys]#LAST# for %d #SLATE#[*]#LAST# turns.
Requires a weapon and shield to use.]])
			:format(get(t.range, self, t),
							get(t.weapon_mult, self, t) * 100,
							self:describeInflict('daze', 'future', get(t.daze, self, t)),
							get(t.radius, self, t),
							get(t.offbalance, self, t))
	end,}

newTalent {
	name = 'Stone Aspect', short_name = 'WEIRD_STONE_ASPECT',
	type = {'wild-gift/stone-aspect', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	bash_chance = function(self, t)
		return self:scale {low = 5, high = 25, t,}
	end,
	equilibrium_gain = function(self, t)
		return self:scale {low = 0.2, high = 2, t,} * 2.5
	end,
	shield_speed = function(self, t)
		return self:scale {low = 10, high = 70, limit = 110, t,}
	end,
	cooldown_mod = function(self, t)
		return self:scale {low = 100, high = 60, limit = 33, t}
	end,
	passives = function(self, t, p)
		self:autoTemporaryValues(
			p, {
				equilibrium_on_block = get(t.equilibrium_gain, self, t),
				combat_shield_speed = get(t.shield_speed, self, t),
				combat_shield_bash_chance = get(t.bash_chance, self, t),})
	end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate stone as a dragon would. Every time you make a melee strike you have a %d%% #SLATE#[*]#LAST# chance to perform an additional shield bash. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you block damage with your shield. Shield actions are %d%% #SLATE#[*]#LAST# faster.
Points in this talent count double for the purposes of draconic form talents. All of your stone aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.bash_chance, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.shield_speed, self, t),
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_STONE_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_STONE_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Stone Claw', short_name = 'WEIRD_STONE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 3,
	on_pre_use = shield_pre_use,
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
	weapon_mult = function(self, t) return self:scale {low = 1.4, high = 2.8, t,} end,
	requires_target = true,
	tactical = {ATTACK = 2,},
	requires_target = true,
	range = 1,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	speed = 'shield',
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		self:alterTalentCoolingdown('T_BLOCK', -1)

		local shield = (self:hasShield() or self).special_combat
		local weapon_mult = get(t.weapon_mult, self, t)
		local speed, hit = self:attackTargetWith(actor, shield, nil, weapon_mult)

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		self:useEnergy(game.energy_to_act * speed)

		return true
	end,
	info = function(self, t)
		return ([[Hit the target with your shield for %d%% #SLATE#[*]#LAST# weapon damage. This will also reduce the cooldown of block by 1.
Requires a weapon and shield to use.]])
			:format(get(t.weapon_mult, self, t) * 100)
	end,}

newTalent {
	name = 'Stone Drake Aura', short_name = 'WEIRD_STONE_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 16,
	is_mind = true,
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
	radius = function(self, t) return self:scale {low = 2, high = 5, limit = 8, t, after = 'floor',} end,
	damage = function(self, t) return self:scale {low = 70, high = 280, t, 'phys', after = 'damage',} end,
	stun = function(self, t)
		return {duration = get(t.stun_dur, self ,t),
						duration_scale = ' #SLATE#[*]#LAST#',}
	end,
	stun_dur = function(self, t) return self:scale {low = 1.5, high = 2.5, limit = 3.5, t, after = 'ceil',} end,
	pin = function(self, t)
		return {duration = get(t.pin_dur, self ,t),
						duration_scale = ' #SLATE#[*]#LAST#',}
	end,
	pin_dur = function(self, t) return self:scale {low = 1.5, high = 2.5, limit = 3.5, t, after = 'ceil',} end,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local radius = get(t.radius, self, t)
		game.level.map:particleEmitter(
			self.x, self.y, tg.radius, 'shout', {
				additive = true, life = 10, size = 3, distorion_factor = 0.5,
				radius = tg.radius, nb_circles = 8,
				rm = 0.8, rM = 1.0,
				gm = 0.0, gM = 0.0,
				bm = 0.1, bM = 0.2,
				am = 0.4, aM = 0.6,})
		game:playSoundNear(self, 'talents/earth')

		local damage = self:mindCrit(get(t.damage, self, t))
		local stun = get(t.stun, self, t)
		local pin = get(t.pin, self, t)
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			self:projectOn(actor, 'PHYSICAL', damage)
			self:inflict('stun', actor, stun)
			self:inflict('pin', actor, pin)
		end
		self:project(tg, self.x, self.y, projector)

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Shake the ground in radius %d #SLATE#[*]#LAST#, dealing %d #SLATE#[*, phys, mind crit]#LAST# physical damage and inflicting %s and %s.]])
			:format(get(t.radius, self, t),
							dd(self, 'PHYSICAL', get(t.damage, self, t)),
							self:describeInflict('stun', nil, get(t.stun, self, t)),
							self:describeInflict('pin', nil, get(t.pin, self, t)))
	end,}

newTalent {
	name = 'Stone Breath', short_name = 'WEIRD_STONE_BREATH',
	type = {'wild-gift/draconic-breath', 1,}, hide = true,
	points = 5,
	equilibrium = 12,
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
	is_mind = true,
	radius = function(self, t) return self:scale {low = 5, high = 9, t, after = 'floor',} end,
	damage = function(self, t)
		return self:scale {low = 38, high = 380, t, 'phys', after = 'damage',}
	end,
	petrify = function(self, t)
		return {duration = self:scale {low = 1.5, high = 5.5, limit = 7, t, after = 'ceil',},
						duration_scale = ' #SLATE#[*]#LAST#',}
	end,
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
		local petrify = get(t.petrify, self, t)
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			self:projectOn(actor, 'PHYSICAL', damage)
			self:inflict('petrify', actor, petrify)

			if actor.dead then kills = kills + 1 end
		end
		self:project(tg, x, y, projector)

		self:alterTalentCoolingdown('T_WEIRD_HEAVY_IMPACT', -kills)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_dark', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img='sandwings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		--game.log('%s', self:describeInflict('petrify', nil, get(t.petrify, self, t)))
		return ([[Breathe a petrifying gas at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# physical damage in a radius %d #SLATE#[*]#LAST# cone. It will %s
Every enemy killed in the initial blast will reduce the cooldown of Heavy Impact by 1.]])
			:format(dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.radius, self, t),
							self:describeInflict('petrify', nil, get(t.petrify, self, t)))
	end,}
