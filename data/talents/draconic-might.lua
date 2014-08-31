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
	type = 'wild-gift/draconic-might',
	name = 'Draconic might',
	description = 'Assume the physical traits of a dragon.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Rending Claws', short_name = 'WEIRD_RENDING_CLAWS',
	type = {'wild-gift/draconic-might', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 2,
	cooldown = 3,
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 1.0, high = 2.0, t,} end,
	armor_per = function(self, t)
		return math.min(self:scale {low = 10, high = 40, 'phys',},
										get(t.armor_max, self, t))
	end,
	armor_max = function(self, t) return self:scale {low = 20, high = 90, t,} end,
	duration = 5,
	tactical = {ATTACK = 2,},
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	requires_target = true,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local weapon_mult = get(t.weapon_mult, self, t)
		local armor_per = get(t.armor_per, self, t)
		local armor_max = get(t.armor_max, self, t)
		local duration = get(t.duration, self, t)

		if self:attackTarget(actor, nil, weapon_mult, true) then
			actor:setEffect('EFF_WEIRD_ARMOR_REND', duration, {
												 src = self,
												 apply_power = self:combatPhysicalpower(),
												 armor_per = armor_per,
												 armor_max = armor_max,})
		end

		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent target for %d%% #SLATE#[*]#LAST# weapon damage. If you hit, you will #ORANGE#rend their armour#LAST# #SLATE#[phys vs phys]#LAST#, removing %d #SLATE#[phys]#LAST# points of armour for %d turns. This can stack up to a total of %d #SLATE#[*]#LAST# armour loss.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.armor_per, self, t),
							get(t.duration, self, t),
							get(t.armor_max, self, t))
	end,}

newTalent {
	name = 'Bellowing Roar', short_name = 'WEIRD_BELLOWING_ROAR',
	type = {'wild-gift/draconic-might', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 3,
	cooldown = 20,
	range = 0,
	radius = function(self, t) return self:scale {low = 3, high = 7, limit = 10, t, after = 'floor',} end,
	damage = function(self, t) return self:scale {low = 30, high = 300, 'phys', t, after = 'damage',} end,
	confuse = function(self, t) return self:scale {low = 30, high = 60, limit = 80, t,} end,
	duration = 3,
	no_silence = true,
	tactical = { DEFEND = 1, DISABLE = { confusion = 3 } },
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local damage = get(t.damage, self, t)
		local confuse = get(t.confuse, self, t)
		local duration = math.floor(self:mindCrit(get(t.duration, self, t)))
		local apply_power = self:combatPhysicalpower()
		local projector = function(x, y)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			self:projectOn(actor, 'PHYSICAL', damage)
			if actor:canBe 'confusion' then
				actor:setEffect('EFF_CONFUSED', duration, {
													apply_power = apply_power,
													apply_save = 'combatPhysicalResist',
													power = confuse,})
			end
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

		return true
	end,
	info = function(self, t)
		return ([[Let out a powerful roar in a radius of %d #SLATE#[*]#LAST#, hitting enemies for %d #SLATE#[*, phys]#LAST# physical damage and #CCCC11#confusing#LAST# #SLATE#[phys vs phys, confuse]#LAST# them with %d%% #SLATE#[*]#LAST# power for %d #SLATE#[mind crit]#LAST# turns.]])
			:format(get(t.radius, self, t),
							dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.confuse, self, t),
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Wing Buffet', short_name = 'WEIRD_WING_BUFFET',
	type = {'wild-gift/draconic-might', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 7,
	cooldown = function(self, t) return self:scale {low = 20, high = 13, limit = 9, t, after = 'ceil',} end,
	range = 0,
	radius = function(self, t) return self:scale {low = 4, high = 9, limit = 10, t, after = 'ceil',} end,
	knockback = function(self, t)
		return {distance = self:scale {low = 2, high = 5, limit = 8, t, after = 'floor',},
						distance_scale = ' #SLATE#[*]#LAST#',}
	end,
	direct_hit = true,
	random_ego = 'attack',
	requires_target = true,
	tactical = { DEFEND = { knockback = 2 }, ESCAPE = { knockback = 2 } },
	target = function(self, t)
		return {type = 'cone', talent = t, selffire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end

		local knockback = get(t.knockback, self, t)
		local projector = function(x, y)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			self:inflict('knockback', actor, knockback)
		end
		self:project(tg, x, y, projector)

		game:playSoundNear(self, 'talents/breath')
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		self:knockback(x, y, knockback.distance)

		return true
	end,
	info = function(self, t)
		return ([[With a powerful flap of wings, hit targets in a radius %d #SLATE#[*]#LAST# cone, trying to %s
This will also move you backwards by the same number of tiles.]])
			:format(get(t.radius, self, t),
							self:describeInflict('knockback', false, get(t.knockback, self, t)))
	end,}

newTalent {
	name = 'Swallow', short_name = 'WEIRD_SWALLOW',
	type = {'wild-gift/draconic-might', 4,},
	require = make_require(4),
	points = 5,
	equilibrium = 7,
	no_npc_use = true,
	cooldown = 8,
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 1.0, high = 1.9, t,} end,
	life_threshold = function(self, t, target)
		local mult = 100
		if target then
			mult = mult * ((self.size_category or 3) + self.rank) / ((target.size_category or 3) + target.rank)
		end
		return self:scale {low = 10, high = 30, limit = 50, t, 'con', mult,}
	end,
	duration = function(self, t) return self:scale {low = 4, high = 8, t, after = 'floor',} end,
	power = function(self, t) return self:scale {low = 2, high = 8, t, 'mind',} end,
	healmod = function(self, t) return self:scale {low = 3, high = 7, t,} end,
	equi_regen = function(self, t) return self:scale {low = 0, high = 1, 'wil',} end,
	stacks = function(self, t)
		return self:scale {low = 1, high = 12, 'con', after = 'floor',}
	end,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end
		game.logSeen(self, ('%s tries to #UMBER#swallow#LAST# %s!'):format(self.name:capitalize(), actor.name))

		local weapon_mult = get(t.weapon_mult, self, t)
		if not self:attackTarget(actor, 'PHYSICAL', weapon_mult, true) then return true end

		local life_pct = actor.life / actor.max_life
		if not actor.dead and life_pct > 0.05 then
			if not rng.percent(get(t.life_threshold, self, t, actor)) then return true end
			if not actor:canBe 'instakill' then return true end
			if not actor:checkHit(self:combatPhysicalpower(), actor:combatPhysicalResist()) then return true end
		end

		if not actor.dead then actor:die(self) end
		-- world:gainAchievement('EAT_BOSSES', self, actor)

		local duration = get(t.duration, self, t)
		self:setEffect('EFF_WEIRD_APPETITE', duration, {
										 original_duration = duration,
										 stacks = math.floor(actor.rank),
										 max_stacks = get(t.stacks, self, t),
										 power = get(t.power, self, t),
										 healmod = get(t.healmod, self, t),
										 equi_regen = get(t.equi_regen, self, t),})
		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent target for %d%% #SLATE#[*]#LAST# physical damage. If this hits and kills it or brings it below %d%% #SLATE#[*, con, relative rank and size]#LAST# life, attempt to #UMBER#Swallow#LAST# #SLATE#[phys vs. phys, auto below 5%% life]#LAST# it, killing it instantly.
This will give you the a stack of the #UMBER#Appetite#LAST# buff for each rank of the enemy, up to your maximum of %d #SLATE#[con]#LAST# stacks. You will get %.1f #SLATE#[*, mind]#LAST# physical power, %.1f%% #SLATE#[*]#LAST# healing modifier, and %.2f #SLATE#[wil]#LAST# #00FF74#equilibrium#LAST# regeneration per stack. #UMBER#Appetite#LAST# will last for %d #SLATE#[*]#LAST# turns, which will refresh every time it is applied. A single stack will be lost when the timer runs out.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.life_threshold, self, t),
							get(t.stacks, self, t),
							get(t.power, self, t),
							get(t.healmod, self, t),
							get(t.equi_regen, self, t),
							get(t.duration, self, t))
	end,}
