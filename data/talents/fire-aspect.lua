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
	cooldown = function(self, t)
		local cd = 16
		if self:knowTalent('T_WEIRD_FIRE_ASPECT') then
			cd = cd - self:callTalent('T_WEIRD_FIRE_ASPECT', 'cooldown_reduce')
		end
		return cd
	end,
	damage = function(self, t) return self:wwScale {min = 1.3, max = 2.0, talent = t,} end,
	range = function(self, t) return self:wwScale {min = 3, max = 6, stat = 'str', round = 'floor',} end,
	duration = function(self, t) return self:wwScale {min = 2, max = 5, talent = t, stat = 'wil',} end,
	project = function(self, t)
		return self:wwScale {min = 5, max = 35, talent = t, stat = 'wil', scale = 'damage',}
	end,
	sight = function(self, t) return -self:wwScale {min = 6, max = 3, stat = 'wil', round = 'floor',} end,
	requires_target = true,
	tactical = {ATTACK = 2,},
	requires_target = true,
	target = function(self, t)
		return {type = 'hit', talent = t, range = util.getval(t.range, self, t),}
	end,
	on_pre_use = function(self, t) return not self:attr('never_move') end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
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
			self:setEffect('EFF_WEIRD_BURNING_RAGE', util.getval(t.duration, self, t), {
											 src = self,
											 sight = util.getval(t.sight, self, t),
											 project = util.getval(t.project, self, t),})
			self:attackTarget(actor, nil, util.getval(t.damage, self, t), true)
			return true
		end
	end,
	info = function(self, t)
		return ([[Rush forward in a #ORANGE#blind rage#LAST#, striking a target within %d #SLATE#[str]#LAST# spaces for %d%% weapon damage.
This will last for %d #SLATE#[wil]#LAST# turns, giving you %d #SLATE#[wil]#LAST# extra #LIGHT_RED#fire#LAST# damage on melee attacks, but reducing your vision radius by %d #SLATE#[wil]#LAST#.]])
			:format(util.getval(t.range, self, t),
							util.getval(t.damage, self, t) * 100,
							util.getval(t.duration, self, t),
							dd(self, 'FIRE', util.getval(t.project, self, t)),
							0	- util.getval(t.sight, self, t))
	end,}

newTalent {
	name = 'Focused Fury', short_name = 'WEIRD_FOCUSED_FURY',
	type = {'wild-gift/fire-aspect', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	sustain_equilibrium = 20,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	equilibrium_cost = function(self, t)
		return self:wwScale {min = 4, max = 1, stat = 'wil', round = 'ceil',}
	end,
	life_percent = function(self, t)
		return self:wwScale {min = 0.10, max = 0.05, talent = t,}
	end,
	combat_mentalresist = function(self, t)
		return self:wwScale {min = 5, max = 30, stat = 'wil', talent = t,}
	end,
	combat_physspeed = function(self, t)
		return self:wwScale {min = 0.02, max = 0.20, stat = 'wil', talent = t,}
	end,
	confusion_immune = function(self, t)
		return self:wwScale {min = 0.02, max = 0.10, talent = t,}
	end,
	tactical = {BUFF = 2,},
	passives = function(self, t, p)
		self:effectTemporaryValue(p, 'burning_rage_bonuses', {
																combat_mentalresist = util.getval(t.combat_mentalresist, self, t),
																combat_physspeed = util.getval(t.combat_physspeed, self, t),
																confusion_immune = util.getval(t.confusion_immune, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_WIL then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	damage_feedback = function(self, t, p, src, value)
		local rage = self:hasEffect('EFF_WEIRD_BURNING_RAGE')
		if rage then
			rage.damage_taken = (rage.damage_taken or 0) + value
		end
	end,
	info = function(self, t)
		return ([[This will passively enhance your #ORANGE#Burning Rage#LAST#. It will now give you +%d #SLATE#[wil]#LAST# mental save, +%d%% #SLATE#[wil]#LAST# combat speed, and +%d%% #SLATE#[wil]#LAST# confusion immunity.
While active, on any turn on which you are raging and take damage totaling at least %d%% of your life, your equilibrium will increase by %d #SLATE#[wil]#LAST# and your #ORANGE#Burning Rage#LAST# will be extended by 1 turn, provided you pass an equilibrium check.]])
			:format(util.getval(t.combat_mentalresist, self, t),
							util.getval(t.combat_physspeed, self, t) * 100,
							util.getval(t.confusion_immune, self, t) * 100,
							util.getval(t.life_percent, self, t) * 100,
							util.getval(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Fan the Flames', short_name = 'WEIRD_FAN_THE_FLAMES',
	type = {'wild-gift/fire-aspect', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 7,
	tactical = {ATTACK = 2,},
	range = 1,
	cooldown = function(self, t)
		return not self:hasEffect('EFF_WEIRD_BURNING_RAGE') and 10 or
			util.getval(t.rage_cooldown, self, t)
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	rage_cooldown = function(self, t)
		return self:wwScale {min = 10, max = 4.5, limit = 2, talent = t, round = 'floor',}
	end,
	radius = function(self, t)
		return self:wwScale {min = 1, max = 3, stat = 'str', round = 'floor',}
	end,
	damage = function(self, t)
		return self:wwScale {min = 1.2, max = 2.0, talent = t,}
	end,
	duration = 5,
	fire_mult = function(self, t)
		return self:wwScale {min = 1.0, max = 1.25, stat = 'wil',}
	end,
	target = function(self, t)
		return {type = 'hit', range = util.getval(t.range, self, t), talent = t,}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local damage = util.getval(t.damage, self, t)
		if self:attackTarget(actor, nil, damage, true) then
			local burn = actor:hasEffect('EFF_BURNING')
			if burn then
				local power = burn.power * burn.dur
				actor:removeEffect('EFF_BURNING')
				damage_type:get('FIRE').projector(
					self, actor.x, actor.y, 'FIRE', power)

				local radius = util.getval(t.radius, self, t)
				game.level.map:particleEmitter(actor.x, actor.y, radius + 2, 'ball_fire', {radius = radius + 2,})
				game:playSoundNear(self, 'talents/fire')

				local duration = util.getval(t.duration, self, t)
				local effect = game.level.map:addEffect(
					self, actor.x, actor.y, duration, 'FIRE', power / duration,
					radius, 5, nil, {type = 'inferno',}, nil, 0, 0)
				effect.name = ('%s\'s flames'):format(self.name:capitalize())
			end
		end

		return true
	end,
	info = function(self, t)
		return ([[Strike the target for %d%% weapon damage. If the target is currently burning, this will consume the flames on the target to deal %d%% #SLATE#[wil]#LAST# of the total damage instantly, and will leave flames on the ground in radius %d #SLATE#[str]#LAST# dealing the same amount of damage over %d turns.
This talent only has a %d turn cooldown if used while in a #ORANGE#Burning Rage#LAST#.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.fire_mult, self, t) * 100,
							util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							util.getval(t.rage_cooldown, self, t))
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
		return self:wwScale {min = 5, max = 35, talent = t, stat = 'wil',}
	end,
	resists_pen = function(self, t)
		return self:wwScale {min = 3, max = 10, talent = t,}
	end,
	equilibrium_gain = function(self, t)
		return self:wwScale {min = 0.2, max = 2, talent = t,}
	end,
	cooldown_reduce = function(self, t)
		return self:wwScale {min = 1, max = 6, talent = t, round = 'floor',}
	end,
	passives = function(self, t, p)
		self:effectTemporaryValue(
			p, 'equilibrium_on_damage', {FIRE = util.getval(t.equilibrium_gain, self, t),})
		self:effectTemporaryValue(
			p, 'inc_damage', {FIRE = util.getval(t.inc_damage, self, t),})
		self:effectTemporaryValue(
			p, 'resists_pen', {FIRE = util.getval(t.resists_pen, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_WIL then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate flame as a dragon would. You gain %d%% #SLATE#[wil]#LAST# to all #LIGHT_RED#fire#LAST# damage done, and %d%% #LIGHT_RED#fire#LAST# resistance piercing. You regain %.1f equilibrium on any turn in which you deal #LIGHT_RED#fire#LAST# damage.
This also reduces the cooldown of Raging Rush by %d.
Points in this talent count double for the purposes of draconic form talents.]])
			:format(util.getval(t.inc_damage, self, t),
							util.getval(t.resists_pen, self, t),
							util.getval(t.equilibrium_gain, self, t),
							util.getval(t.cooldown_reduce, self, t))
	end,}

newTalent {
	name = 'Fire Claw', short_name = 'WEIRD_FIRE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 3,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_CLAW', 'shared_cooldown')
	end,
	damage = function(self, t) return self:wwScale {min = 1.5, max = 2.5, talent = t,} end,
	requires_target = true,
	tactical = {ATTACK = 2,},
	requires_target = true,
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
		self:attackTarget(actor, 'FIREBURN', damage, true)
		game:playSoundNear(self, 'talents/fire')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% weapon #LIGHT_RED#fire burn#LAST# damage.]])
			:format(util.getval(t.damage, self, t) * 100)
	end,}

newTalent {
	name = 'Fire Drake Aura', short_name = 'WEIRD_FIRE_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 16,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_AURA', 'shared_cooldown')
	end,
	tactical = {ATTACKAREA = 2,},
	range = 0,
	radius = function(self, t) return self:wwScale {min = 2, max = 4, talent = t,} end,
	damage = function(self, t)
		return self:wwScale {
			min = 10, max = 60, talent = t, stat = 'str', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 2, max = 4, stat = 'str',} end,
	intimidate = function(self, t) return self:wwScale {min = 5, max = 50, talent = t, stat = 'wil',} end,
	intimidate_dur = function(self, t)
		return self:wwScale {min = 3, max = 10, stat = 'wil', round = 'floor',}
	end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)

		local radius = util.getval(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_fire', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/fire')

		local damage = util.getval(t.damage, self, t)
		local duration = util.getval(t.duration, self, t)
		local effect = game.level.map:addEffect(
			self, self.x, self.y, duration, 'FIRE', damage,
			radius, 5, nil, {type = 'inferno',}, nil, 0, 0)
		effect.name = ('%s\'s flames'):format(self.name:capitalize())

		local intimidate = util.getval(t.intimidate, self, t)
		local intimidate_dur = util.getval(t.intimidate_dur, self, t)
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

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Set the ground around you alight in radius %d, dealing %d #SLATE#[str]#LAST# #LIGHT_RED#fire#LAST# damage for %d #SLATE#[str]#LAST# turns. Each enemy standing on one of these tiles will be intimidated #SLATE#[phys vs mind, checks (fear immunity + fire resistance)]#LAST#, losing %d #SLATE#[wil]#LAST# physical, spell, and mind power for %d #SLATE#[wil]#LAST# turns.]])
			:format(util.getval(t.radius, self, t),
							dd(self, 'FIRE', util.getval(t.damage, self, t)),
							util.getval(t.duration, self, t),
							util.getval(t.intimidate, self ,t),
							util.getval(t.intimidate_dur, self ,t))
	end,}

newTalent {
	name = 'Fire Breath', short_name = 'WEIRD_FIRE_BREATH',
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
			min = 40, max = 400, talent = t, stat = 'str', scale = 'damage',}
	end,
	ground_damage = function(self, t)
		return self:wwScale {
			min = 20, max = 120, talent = t, stat = 'str', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 3, max = 7, stat = 'str',} end,
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
		local ground_damage = util.getval(t.duration, self, t)
		local rage = self:hasEffect('EFF_WEIRD_BURNING_RAGE')
		local projector = function(x, y, tg, self)
			local effect = game.level.map:addEffect(
				self, x, y, duration, 'FIREBURN', ground_damage,
				0, 5, nil, {type = 'inferno',}, nil, 0, 0)
			effect.name = ('%s\'s fire breath'):format(self.name:capitalize())

			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			damage_type:get('FIRE').projector(self, x, y, 'FIRE', damage)

			if actor.dead and rage then rage.dur = rage.dur + 1 end
		end
		self:project(tg, x, y, projector)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_fire', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Breathe fire at your foes, doing %d #SLATE#[str]#LAST# #LIGHT_RED#fire#LAST# damage #SLATE#[mind crit]#LAST# in a radius %d cone. It will also leave burning flames on the ground for %d #SLATE#[str]#LAST# turns, doing %d #SLATE#[str]#LAST# #LIGHT_RED#fire burn#LAST# damage each turn.
Every enemy killed in the initial blast will raise your burning rage duration by 1, if you have it.]])
			:format(dd(self, 'FIRE', util.getval(t.damage, self, t)),
							util.getval(t.radius, self, t),
							util.getval(t.duration, self, t),
							dd(self, 'FIRE', util.getval(t.ground_damage, self ,t)))
	end,}
