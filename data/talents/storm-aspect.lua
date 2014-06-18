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
	type = 'wild-gift/storm-aspect',
	name = 'Storm Aspect',
	description = 'Channel the lightning reflexes of the storm drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Lightning Speed', short_name = 'WEIRD_LIGHTNING_SPEED',
	type = {'wild-gift/storm-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 4,
	no_energy = true,
	cooldown = function(self, t)
		local cd = 20
		if self:knowTalent('T_WEIRD_STORM_ASPECT') then
			cd = cd - self:callTalent('T_WEIRD_STORM_ASPECT', 'cooldown_reduce')
		end
		return cd
	end,
	speed = function(self, t) return self:wwScale {min = 2, max = 6, talent = t, stat = 'str',} end,
	duration = function(self, t) return self:wwScale {min = 0.8, max = 2.3, talent = t, round = 'ceil',} end,
	evasion = function(self, t) return self:wwScale {min = 10, max = 40, stat = 'str',} end,
	tactical = {ESCAPE = 2,},
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local later = function()
			local duration = util.getval(t.duration, self, t)
			self:setEffect('EFF_WEIRD_LIGHTNING_SPEED', duration, {
											 speed = util.getval(t.speed, self, t),
											 evasion = util.getval(t.evasion, self, t),})
		end
		game:onTickEnd(later)
		return true
	end,
	info = function(self, t)
		return ([[#38FF98#Speed up#LAST# gaining %d%% #SLATE#[str]#LAST# movement speed and %d%% #SLATE#[str]#LAST# evasion for %d turns.]])
			:format(util.getval(t.speed, self, t) * 100,
							util.getval(t.evasion, self, t),
							util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Jitter', short_name = 'WEIRD_JITTER',
	type = {'wild-gift/storm-aspect', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	sustain_equilibrium = 20,
	equilibrium_cost = function(self, t)
		return self:wwScale {min = 3.0, max = 1.0, limit = 0.4, talent = t, stat = 'str',}
	end,
	dodge_percent = function(self, t)
		return self:wwScale {min = 0.2, max = 1.0, talent = t, stat = 'wil',}
	end,
	dodge_duration = function(self, t)
		return self:wwScale {min = 1.4, max = 2.4, stat = 'wil', round = 'floor',}
	end,
	tactical = {BUFF = 2,},
	activate = function(self, t) return {moved = true,} end,
	deactivate = function(self, t, p) return true end,
	callbackOnMove = function(self, t, moved, force, ox, oy)
		local p = self:isTalentActive(t.id)
		if ox ~= self.x or oy ~= self.y then p.moved = true end
	end,
	callbackOnActBase = function(self, t)
		local p = self:isTalentActive(t.id)
		if p.damaged and not p.moved then
			self:incEquilibrium(util.getval(t.equilibrium_cost, self, t))
		end
		p.moved = false
		p.damaged = false
	end,
	damage_feedback = function(self, t, p, src, value)
		if value > 0 then
			p.damaged = true
			local chance = util.getval(t.dodge_percent, self, t)
			if rng.percent(chance * 100 * value / self.max_life) then
				if self:equilibriumChance() then
					local duration = util.getval(t.dodge_duration, self, t)
					game:playSoundNear(self, 'talents/lightning')
					-- On end of tick so it doesn't block this hit.
					local later = function() self:setEffect('EFF_WEIRD_PURE_LIGHTNING', duration, {}) end
					game:onTickEnd(later)
				else
					self:forceUseTalent('T_WEIRD_JITTER', {ignore_energy = true,})
				end
			end
		end
	end,
	info = function(self, t)
		return ([[While active, whenever you take life damage, you have a chance equal to %.2f #SLATE#[wil]#LAST# times the percentage of max life you lost to turn into #ROYAL_BLUE#pure lightning#LAST# for %d #SLATE#[wil]#LAST# turns, completely dodging a single attack per turn by moving to an adjacent space. Trying to turn into #ROYAL_BLUE#pure lightning#LAST# will trigger an equilibrium check, deactivating this talent if you fail.
This will increase your #6FFF83#equilibrium#LAST# by %.2f on any game turn in which you take damage and did not move.]])
			:format(util.getval(t.dodge_percent, self, t),
							util.getval(t.dodge_duration, self, t),
							util.getval(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Rapid Strikes', short_name = 'WEIRD_RAPID_STRIKES',
	type = {'wild-gift/storm-aspect', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 7,
	range = 1,
	cooldown = function(self, t)
		return self:wwScale {min = 8, max = 5, limit = 3, talent = t, round = 'ceil',}
	end,
	damage = function(self, t)
		return self:wwScale {min = 1, max = 1.4, talent = t,}
	end,
	project = function(self, t)
		return self:wwScale {min = 5, max = 35, talent = t, stat = 'wil', scale = 'damage',}
	end,
	speed = function(self, t)
		return self:wwScale {min = 0.1, max = 0.35, talent = t,}
	end,
	tactical = {ATTACK = 1,},
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

		local damage = util.getval(t.damage, self, t)
		if self:attackTarget(actor, nil, damage, true) then
			self:setEffect('EFF_WEIRD_RAPID_STRIKES', 1, {
											 target = actor,
											 speed = util.getval(t.speed, self, t),
											 project = util.getval(t.project, self, t),})
		end
		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent target with your weapon for %d%% damage. If this hits, you will gain %d #SLATE#[wil]#LAST# #ROYAL_BLUE#lightning#LAST# damage on hit and %d%% combat speed. You will lose this bonus when you take an action that does not result in the original target taking #ROYAL_BLUE#lightning#LAST# damage.]])
			:format(util.getval(t.damage, self, t) * 100,
							dd(self, 'LIGHTNING', util.getval(t.project, self, t)),
							util.getval(t.speed, self, t) * 100)
	end,}

newTalent {
	name = 'Storm Aspect', short_name = 'WEIRD_STORM_ASPECT',
	type = {'wild-gift/storm-aspect', 4,},
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
			p, 'equilibrium_on_damage', {LIGHTNING = util.getval(t.equilibrium_gain, self, t),})
		self:effectTemporaryValue(
			p, 'inc_damage', {LIGHTNING = util.getval(t.inc_damage, self, t),})
		self:effectTemporaryValue(
			p, 'resists_pen', {LIGHTNING = util.getval(t.resists_pen, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_WIL then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate flame as a dragon would. You gain %d%% #SLATE#[wil]#LAST# to all #ROYAL_BLUE#lightning#LAST# damage done, and %d%% #ROYAL_BLUE#lightning#LAST# resistance piercing. You regain %.1f equilibrium on any turn in which you deal #ROYAL_BLUE#lightning#LAST# damage.
This also reduces the cooldown of #38FF98#Lightning Speed#LAST# by %d.
Points in this talent count double for the purposes of draconic form talents.]])
			:format(util.getval(t.inc_damage, self, t),
							util.getval(t.resists_pen, self, t),
							util.getval(t.equilibrium_gain, self, t),
							util.getval(t.cooldown_reduce, self, t))
	end,}

newTalent {
	name = 'Storm Claw', short_name = 'WEIRD_STORM_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 3,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_CLAW', 'shared_cooldown')
	end,
	damage = function(self, t) return self:wwScale {min = 1.0, max = 1.8, talent = t,} end,
	duration = function(self, t) return self:wwScale {min = 2, max = 5, talent = t, round = 'floor',} end,
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
		local duration = util.getval(t.duration, self, t)
		if self:attackTarget(actor, 'LIGHTNING', damage, true) then
			if actor:canBe('stun') then
				actor:setEffect('EFF_DAZED', duration, {apply_power = self:combatPhysicalpower(),})
			end
			game:playSoundNear(self, 'talents/lightning')
		end

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% weapon #ROYAL_BLUE#lightning#LAST# damage, and attempt to #VIOLET#daze#LAST# #SLATE#[phys vs. phys, stun]#LAST# for %d turns.]])
			:format(util.getval(t.damage, self, t) * 100,
							util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Storm Drake Aura', short_name = 'WEIRD_STORM_AURA',
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
			min = 30, max = 300, talent = t, power = 'mind', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 2, max = 7, talent = t, round = 'floor',} end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false, friendlyfire = false,
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = util.getval(t.target, self, t)

		local radius = util.getval(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_lightning', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/lightning')

		local damage = self:mindCrit(util.getval(t.damage, self, t))
		local duration = util.getval(t.duration, self, t)
		local power = self:combatMindpower()
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			damage_type:get('LIGHTNING').projector(self, x, y, 'LIGHTNING', damage)
			if actor:canBe('stun') then
				actor:setEffect('EFF_DAZED', duration, {apply_power = power,})
			end
		end
		self:project(tg, self.x, self.y, projector)
		game:playSoundNear(self, 'talents/lightning')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Produce a radius %d electric shock, dealing %d #SLATE#[mind]#LAST# #ROYAL_BLUE#lightning#LAST# damage and attempting to #VIOLET#daze#LAST# #SLATE#[mind vs phys]#LAST# them for %d turns.]])
			:format(util.getval(t.radius, self, t),
							dd(self, 'LIGHTNING', util.getval(t.damage, self, t)),
							util.getval(t.duration, self, t))
	end,}

newTalent {
	name = 'Storm Breath', short_name = 'WEIRD_STORM_BREATH',
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
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			local real_damage = damage * (1 + actor.life / actor.max_life)
			damage_type:get('LIGHTNING').projector(self, x, y, 'LIGHTNING', real_damage)

			if actor.dead then kills = kills + 1 end
		end
		self:project(tg, x, y, projector)

		local speed = self:hasEffect('EFF_WEIRD_LIGHTNING_SPEED')
		if speed and kills > 0 then
			if speed.is_low then
				speed.dur = speed.dur + kills
			else
				speed.duration_low = speed.duration_low + kills
			end
		end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_lightning', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img = 'lightningwings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Breathe lightning at your foes, doing %d #SLATE#[str]#LAST# #ROYAL_BLUE#lightning#LAST# damage #SLATE#[mind crit]#LAST# in a radius %d cone. Damage will be increased by the target's percentage of life remaining. #SLATE#(So a target at full health takes double damage.)#LAST#
Every enemy killed in the initial blast will raise your #38FF98#Lightning Speed#LAST# duration by 1, if you have it. This applies to the second part of the effect, even if you currently have the first part active.]])
			:format(dd(self, 'LIGHTNING', util.getval(t.damage, self, t)),
							util.getval(t.radius, self, t))
	end,}
