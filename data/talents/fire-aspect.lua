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
	type = 'wild-gift/fire-aspect',
	name = 'Fire Aspect',
	description = 'Channel the pure rage of the fire drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Raging Rush', short_name = 'WEIRD_RAGING_RUSH',
	type = {'wild-gift/fire-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 4,
	cooldown = 12,
	no_energy = 'fake',
	weapon_mult = function(self, t) return self:scale {low = 1.3, high = 2.0, t,} end,
	range = 4,
	duration = function(self, t) return self:scale {low = 5, high = 12, t, after = 'floor',} end,
	project = function(self, t)
		return self:scale {low = 10, high = 50, 'mind', after = 'damage',}
	end,
	sight = function(self, t)
		return self:scale {low = -6, high = -2, limit = 0, t, after = 'floor',}
	end,
	tactical = {ATTACK = 2,},
	requires_target = true,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	on_pre_use = function(self, t) return not self:attr('never_move') end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local block = function(_, x, y)
			return game.level.map:checkEntity(x, y, map.TERRAIN, 'block_move', self)
		end
		local line = self:lineFOV(x, y, block)
		local tx, ty = self.x, self.y
		local lx, ly, blocked = line:step()
		while not blocked and lx and ly and
			not game.level.map:checkAllEntities(lx, ly, 'block_move', self)
		do
			tx, ty = lx, ly
			lx, ly, blocked = line:step()
		end

		if not tx or not ty or core.fov.distance(x, y, tx, ty) > 1 then return end

		local sx, sy = self.x, self.y
		self:move(tx, ty, true)
		if config.settings.tome.smooth_move > 0 then
			self:resetMoveAnim()
			self:setMoveAnim(sx, sy, 8, 5)
		end

		if core.fov.distance(self.x, self.y, x, y) == 1 then
			local eff = {
				src = self,
				temps = {
					sight = get(t.sight, self, t),
					melee_project = {FIREBURN = get(t.project, self, t),},},}
			if self:knowTalent 'T_WEIRD_FOCUSED_FURY' then
				local t2 = self:getTalentFromId 'T_WEIRD_FOCUSED_FURY'
				eff.temps.combat_mentalresist = get(t2.combat_mentalresist, self ,t2)
				eff.temps.combat_physspeed = get(t2.combat_physspeed, self ,t2)
				eff.temps.confusion_immune = get(t2.confusion_immune, self ,t2)
			end
			self:setEffect('EFF_WEIRD_BURNING_RAGE', get(t.duration, self, t), eff)
			self:attackTarget(actor, nil, get(t.weapon_mult, self, t))
			return true
		end
	end,
	info = function(self, t)
		return ([[Rush forward in a #ORANGE#Burning Rage#LAST#, striking a target within %d tiles for %d%% #SLATE#[*]#LAST# weapon damage.
The #ORANGE#Burning Rage#LAST# will last for %d #SLATE#[*]#LAST# turns, giving you %d #SLATE#[mind]#LAST# extra #LIGHT_RED#fire burn#LAST# damage on melee attacks, but reducing your vision radius by %d #SLATE#[*]#LAST#, as your rage inhibits peripheral vision.]])
			:format(get(t.range, self, t),
							get(t.weapon_mult, self, t) * 100,
							get(t.duration, self, t),
							dd(self, 'FIRE', get(t.project, self, t)),
							0	- get(t.sight, self, t))
	end,}

newTalent {
	name = 'Fan the Flames', short_name = 'WEIRD_FAN_THE_FLAMES',
	type = {'wild-gift/fire-aspect', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 7,
	tactical = {ATTACK = 2,},
	range = 1,
	no_energy = 'fake',
	cooldown = function(self, t)
		return self:hasEffect 'EFF_WEIRD_BURNING_RAGE' and
			get(t.base_cooldown, self, t) or
			get(t.rage_cooldown, self, t)
	end,
	base_cooldown = 10,
	rage_cooldown = 6,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	radius = function(self, t)
		return self:scale {low = 1, high = 5, limit = 8, t, after = 'floor',}
	end,
	weapon_mult = function(self, t)
		return self:scale {low = 1.2, high = 2.0, t,}
	end,
	duration = 5,
	fire_mult = function(self, t)
		return self:scale {low = 1.0, high = 3.5, t, 'mind',}
	end,
	target = function(self, t)
		return {type = 'hit', range = get(t.range, self, t), talent = t,}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local weapon_mult = get(t.weapon_mult, self, t)
		if self:attackTarget(actor, nil, weapon_mult) then
			local burn = actor:hasEffect('EFF_BURNING')
			if burn then
				local power = burn.power * burn.dur
				actor:removeEffect('EFF_BURNING')
				damage_type:get('FIRE').projector(
					self, actor.x, actor.y, 'FIRE', power)

				local radius = get(t.radius, self, t)
				game.level.map:particleEmitter(actor.x, actor.y, radius + 2, 'ball_fire', {radius = radius + 2,})
				game:playSoundNear(self, 'talents/fire')

				local duration = get(t.duration, self, t)
				local effect = game.level.map:addEffect(
					self, actor.x, actor.y, duration, 'FIRE', power / duration,
					radius, 5, nil, {type = 'inferno',}, nil, 0, 0)
				effect.name = ('%s\'s flames'):format(self.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Strike the target for %d%% #SLATE#[*]#LAST# weapon damage. If the target is currently #LIGHT_RED#Burning#LAST#, this will consume the flames on the target to deal %d%% #SLATE#[*, mind]#LAST# of the total remaining damage instantly, and will leave flames on the ground in radius %d #SLATE#[*]#LAST# dealing the same amount of damage over %d turns.
This talent normally has a %d cooldown, but only has a %d turn cooldown if used while in a #ORANGE#Burning Rage#LAST#.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.fire_mult, self, t) * 100,
							get(t.radius, self, t),
							get(t.duration, self, t),
							get(t.base_cooldown, self, t),
							get(t.rage_cooldown, self, t))
	end,}

newTalent {
	name = 'Focused Fury', short_name = 'WEIRD_FOCUSED_FURY',
	type = {'wild-gift/fire-aspect', 3,},
	require = make_require(3),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	sustain_equilibrium = 20,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	equilibrium_cost = function(self, t)
		return self:scale {low = 2.5, high = 1, t,}
	end,
	life_percent = function(self, t)
		return self:scale {low = 0.10, high = 0.05, limit = 0.01, t,}
	end,
	combat_mentalresist = function(self, t)
		return self:scale {low = 10, high = 80, 'mind', t,}
	end,
	combat_physspeed = function(self, t)
		return self:scale {low = 0, high = 0.25, t,}
	end,
	confusion_immune = function(self, t)
		return self:scale {low = 0, high = 0.3, t,}
	end,
	tactical = {BUFF = 2,},
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	damage_feedback = function(self, t, p, src, value)
		local rage = self:hasEffect 'EFF_WEIRD_BURNING_RAGE'
		if rage then
			rage.damage_taken = (rage.damage_taken or 0) + value
		end
	end,
	info = function(self, t)
		return ([[This will passively enhance your #ORANGE#Burning Rage#LAST#. It will now give you +%d #SLATE#[*, mind]#LAST# mental save, +%d%% #SLATE#[*]#LAST# combat speed, and +%d%% #SLATE#[*]#LAST# confusion immunity.
While active, on any turn on which you are raging and take damage totaling at least %d%% #SLATE#[*]#LAST# of your life, your #00FF74#equilibrium#LAST# will increase by %d #SLATE#[wil]#LAST# and your #ORANGE#Burning Rage#LAST# will be extended by 1 turn, provided you pass an #00FF74#equilibrium#LAST# check.]])
			:format(get(t.combat_mentalresist, self, t),
							get(t.combat_physspeed, self, t) * 100,
							get(t.confusion_immune, self, t) * 100,
							get(t.life_percent, self, t) * 100,
							get(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Fire Aspect', short_name = 'WEIRD_FIRE_ASPECT',
	type = {'wild-gift/fire-aspect', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	inc_damage = function(self, t)
		return self:scale {low = 5, high = 25, t,}
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
				equilibrium_on_damage = {FIRE = get(t.equilibrium_gain, self, t),},
				inc_damage = {FIRE = get(t.inc_damage, self, t),},
				inc_burn_damage = get(t.inc_damage, self, t),
				resists_pen = {FIRE = get(t.resists_pen, self, t),},})
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate flame as a dragon would. You gain %d%% #SLATE#[*]#LAST# to all #LIGHT_RED#fire#LAST# damage done, an additional #SLATE#(multiplicative)#LAST# %d%% #SLATE#[*]#LAST# to all #LIGHT_RED#fire burn#LAST# damage done, and %d%% #SLATE#[*]#LAST# #LIGHT_RED#fire#LAST# resistance piercing. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you deal #LIGHT_RED#fire#LAST# damage.
Points in this talent count double for the purposes of draconic form talents. All of your fire aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.inc_damage, self, t),
							get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_FIRE_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_FIRE_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Fire Claw', short_name = 'WEIRD_FIRE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 3,
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
	weapon_mult = function(self, t) return self:scale {low = 1.5, high = 2.5, t,} end,
	requires_target = true,
	tactical = {ATTACK = 2,},
	requires_target = true,
	range = 1,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		self:attackTarget(actor, 'FIREBURN', get(t.weapon_mult, self, t))
		game:playSoundNear(self, 'talents/fire')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% #SLATE#[*]#LAST# weapon #LIGHT_RED#fire burn#LAST# damage.]])
			:format(get(t.weapon_mult, self, t) * 100)
	end,}

newTalent {
	name = 'Fire Drake Aura', short_name = 'WEIRD_FIRE_AURA',
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
	damage = function(self, t)
		return self:scale {
			low = 15, high = 60, t, 'phys', after = 'damage',}
	end,
	duration = 6,
	intimidate = function(self, t) return self:scale {low = 10, high = 80, t, 'mind',} end,
	intimidate_dur = 7,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local radius = get(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_fire', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/fire')

		local damage = get(t.damage, self, t)
		local duration = get(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration, 'FIREBURN', damage,
			radius, 5, nil, {type = 'inferno',}, nil, 0, 0)
		effect.name = ('%s\'s flames'):format(self.name:capitalize())

		local intimidate = get(t.intimidate, self, t)
		local intimidate_dur = get(t.intimidate_dur, self, t)
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			local resist = util.bound((actor.fear_immune or 0) * 100 + actor:combatGetResist('FIRE'), 0, 100)
			if not rng.percent(resist) then
				actor:setEffect('EFF_INTIMIDATED', intimidate_dur, {
													apply_power = self:combatPhysicalpower(),
													power = intimidate,})
			end
		end
		self:project(tg, self.x, self.y, projector)
		game:playSoundNear(self, 'talents/fire')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Set the ground around you alight in radius %d #SLATE#[*]#LAST#, dealing %d #SLATE#[phys]#LAST# #LIGHT_RED#fire burn#LAST# damage for %d turns. Each enemy standing on one of these tiles will be intimidated #SLATE#[phys vs mind, checks (fear immunity + fire resistance)]#LAST#, losing %d #SLATE#[mind]#LAST# physical, spell, and mind power for %d turns.]])
			:format(get(t.radius, self, t),
							dd(self, 'FIRE', get(t.damage, self, t)),
							get(t.duration, self, t),
							get(t.intimidate, self ,t),
							get(t.intimidate_dur, self ,t))
	end,}

newTalent {
	name = 'Fire Breath', short_name = 'WEIRD_FIRE_BREATH',
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
	radius = function(self, t) return self:scale {low = 5, high = 8, limit = 10, t, after = 'ceil',} end,
	damage = function(self, t)
		return self:scale {low = 40, high = 400, t, 'phys', after = 'damage',}
	end,
	ground_damage = function(self, t)
		return self:scale {low = 20, high = 90, t, 'phys', after = 'damage',}
	end,
	duration = function(self, t) return self:scale {low = 8, high = 12, limit = 16, t, after = 'floor'} end,
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
		local ground_damage = get(t.duration, self, t)
		local kills = 0
		local projector = function(x, y, tg, self)
			local effect = game.level.map:addEffect(
				self, x, y, duration, 'FIREBURN', ground_damage,
				0, 5, nil, {type = 'inferno',}, nil, 0, 0)
			effect.name = ('%s\'s fire breath'):format(self.name:capitalize())

			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			damage_type:get('FIRE').projector(self, x, y, 'FIRE', damage)

			if actor.dead then kills = kills + 1 end
		end
		self:project(tg, x, y, projector)

		self:alterTalentCoolingdown('T_WEIRD_RAGING_RUSH', -kills)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_fire', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Breathe fire at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# #LIGHT_RED#fire#LAST# damage in a radius %d #SLATE#[*]#LAST# cone. It will also leave burning flames on the ground for %d #SLATE#[*]#LAST# turns, doing %d #SLATE#[*, phys]#LAST# #LIGHT_RED#fire burn#LAST# damage each turn.
Every enemy killed in the initial blast will reduce the cooldown of Raging Rush by 1.]])
			:format(dd(self, 'FIRE', get(t.damage, self, t)),
							get(t.radius, self, t),
							get(t.duration, self, t),
							dd(self, 'FIRE', get(t.ground_damage, self ,t)))
	end,}
