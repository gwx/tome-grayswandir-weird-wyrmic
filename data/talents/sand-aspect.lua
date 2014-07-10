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
local dd = Talents.damDesc
local map = require 'engine.Map'
local damage_type = require 'engine.DamageType'
local particles = require 'engine.Particles'

newTalentType {
	type = 'wild-gift/sand-aspect',
	name = 'Sand Aspect',
	description = 'Channel the massive power of the sand drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Sandblaster', short_name = 'WEIRD_SANDBLASTER',
	type = {'wild-gift/sand-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 2,
	no_npc_use = true,
	cooldown = function(self, t)
		local cd = 14
		if self:knowTalent('T_WEIRD_SAND_ASPECT') then
			cd = cd - self:callTalent('T_WEIRD_SAND_ASPECT', 'cooldown_reduce')
		end
		return cd
	end,
	range = 1,
	damage = function(self, t) return self:scale {low = 0.9, high = 1.4, t,} end,
	project = function(self, t) return self:scale {low = 10, high = 80, 'phys', after = 'damage',} end,
	accuracy = function(self, t) return self:scale {low = 10, high = 40, t,} end,
	debuff_duration = function(self, t)
		return self:scale {low = 3, high = 7, t, after = 'floor',}
	end,
	buff_duration = function(self, t)
		return 10
	end,
	defense = function(self, t) return self:scale {low = 5, high = 30, t, 'str',} end,
	resist = function(self, t) return self:scale {low = 0, high = 20, t, 'str',} end,
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	requires_target = true,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local _
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		if actor then
			self:attackTarget(actor, 'PHYSICAL', get(t.damage, self, t), true)
		end

		local project = get(t.project, self, t)
		local dir = util.getDir(x, y, self.x, self.y)
		local sides = util.dirSides(dir)
		local hits = 0
		for _, dir in pairs {5, sides.left, dir, sides.right} do
			local x2, y2 = util.coordAddDir(x, y, dir)
			local actor = game.level.map(x2, y2, map.ACTOR)
			if actor then
				hits = hits + 1
				damage_type:get('PHYSICAL').projector(self, x2, y2, 'PHYSICAL', project)
				actor:setEffect('EFF_WEIRD_PARTIALLY_BLINDED', get(t.debuff_duration, self, t), {
													accuracy = get(t.accuracy, self, t)})
			end
		end

		if hits > 0 then
			self:setEffect('EFF_WEIRD_SAND_BARRIER', get(t.buff_duration, self, t), {
											 defense = get(t.defense, self, t),
											 resist = get(t.resist, self, t),})
		end

		-- Sand Breath particles.
		game.level.map:particleEmitter(
			self.x, self.y, 2, 'breath_earth',
			{radius = 2, tx = 2 * (x - self.x), ty = 2 * (y - self.y),})
		game:playSoundNear(self, 'talents/cloud')

		return true
	end,
	info = function(self, t)
		return ([[Powerfully swing your weapon into the ground and then into an adjacent target for %d%% physical damage. This will kick up sand, hitting the target and the 3 spaces behind it for %d #SLATE#[phys]#LAST# physical damage, and attempting to #GREY#partially blind#LAST# #SLATE#[phys vs phys]#LAST# for %d turns, reducing their accuracy by %d #SLATE#[reduced by blind immunity]#LAST#.
If you hit anything, the kicked up sand will form a #LIGHT_UMBER#Sand Barrier#LAST# around you, giving you %d #SLATE#[str]#LAST# defense and %d%% #SLATE#[str]#LAST# physical resistance for %d turns.]])
			:format(get(t.damage, self, t),
							dd(self, 'PHYSICAL', get(t.project, self, t)),
							get(t.debuff_duration, self, t),
							get(t.accuracy, self, t),
							get(t.defense, self, t),
							get(t.resist, self, t),
							get(t.buff_duration, self, t))
	end,}


--[==[
newTalent {
	name = 'Swallow', short_name = 'WEIRD_SWALLOW',
	type = {'wild-gift/sand-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 9,
	no_npc_use = true,
	cooldown = function(self, t)
		local cd = 17
		if self:knowTalent('T_WEIRD_SAND_ASPECT') then
			cd = cd - self:callTalent('T_WEIRD_SAND_ASPECT', 'cooldown_reduce')
		end
		return cd
	end,
	range = 1,
	damage = function(self, t) return self:wwScale {min = 1.4, max = 2.3, talent = t,} end,
	swallow_percent = function(self, t, target)
		local mult = 1
		if target then
			mult = ((self.size_category or 3) + self.rank) / ((target.size_category or 3) + target.rank)
		end
		return self:wwScale {min = 10, max = 30, limit = 50, talent = t, stat = 'con', mult = mult,}
	end,
	duration = function(self, t)
		local duration = self:wwScale {min = 2, max = 10, talent = t,}
		if self:knowTalent('T_WEIRD_APPETITE') then
			duration = duration + self:callTalent('T_WEIRD_APPETITE', 'duration')
		end
		return math.floor(duration)
	end,
	strength = function(self, t) return self:wwScale {min = 0.5, max = 3, stat = 'wil',} end,
	combat_physresist = function(self, t) return self:wwScale {min = 0.5, max = 3, stat = 'wil',} end,
	max_stacks = function(self, t)
		local stacks = 5
		if self:knowTalent('T_WEIRD_APPETITE') then
			stacks = stacks + self:callTalent('T_WEIRD_APPETITE', 'max_stacks')
		end
		return stacks
	end,
	tactical = {ATTACK = 2,},
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
		game.logSeen(self, ('%s tries to #UMBER#swallow#LAST# %s!'):format(self.name:capitalize(), actor.name))

		local damage = get(t.damage, self, t)
		if not self:attackTarget(actor, 'PHYSICAL', damage, true) then return true end

		if not actor.dead and actor.life / actor.max_life > 0.05 then
			if not rng.percent(get(t.swallow_percent, self, t, actor)) then return true end
			if not actor:canBe('instakill') then return true end
			if not actor:checkHit(self:combatPhysicalpower(), actor:combatPhysicalResist()) then return true end
		end

		if not actor.dead then actor:die(self) end
		-- world:gainAchievement('EAT_BOSSES', self, actor)

		-- Heals (stolen from original)
		self:incEquilibrium(-actor.level - 5)
		self:attr('allow_on_heal', 1)
		self:heal(actor.level * 2 + 5, actor)
		if core.shader.active(4) then
			self:addParticles(Particles.new('shader_shield_temp', 1, {toback=true ,size_factor=1.5, y=-0.3, img='healgreen', life=25}, {type='healing', time_factor=2000, beamsCount=20, noup=2.0}))
			self:addParticles(Particles.new('shader_shield_temp', 1, {toback=false,size_factor=1.5, y=-0.3, img='healgreen', life=25}, {type='healing', time_factor=2000, beamsCount=20, noup=1.0}))
		end
		self:attr('allow_on_heal', -1)

		local duration = get(t.duration, self, t)
		self:setEffect('EFF_WEIRD_SWALLOW', duration, {
										 stacks = math.floor(actor.rank),
										 max_stacks = get(t.max_stacks, self, t),
										 strength = get(t.strength, self, t),
										 combat_physresist = get(t.combat_physresist, self, t),})
		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent target for %d%% physical damage. If this hits and kills it or brings it below %d%% #SLATE#[con, relative rank and size]#LAST# life, attempt to #UMBER#swallow#LAST# #SLATE#[phys vs. phys, auto below 5%% life]#LAST# it, recovering life and equilibrium based on its level.
This will also give you the a stack of the #UMBER#Swallow#LAST# buff for each rank of the enemy, up to your maximum of %d stacks. You will get %.1f #SLATE#[wil]#LAST# strength and %.1f #SLATE#[wil]#LAST# physical save per stack. #UMBER#Swallow#LAST# will last for %d turns, which will refresh every time it is applied.]])
			:format(get(t.damage, self, t) * 100,
							get(t.swallow_percent, self, t),
							get(t.max_stacks, self, t),
							get(t.strength, self, t),
							get(t.combat_physresist, self, t),
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Appetite', short_name = 'WEIRD_APPETITE',
	type = {'wild-gift/sand-aspect', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	sustain_equilibrium = 20,
	duration = function(self, t)
		return self:wwScale {min = 0, max = 7, talent = t,}
	end,
	equilibrium_cost = function(self, t)
		return self:wwScale {min = 4, max = 1, stat = 'str', round = 'ceil',}
	end,
	max_stacks = function(self, t)
		return self:wwScale {min = 1, max = 5, talent = t,}
	end,
	bite_chance = function(self, t)
		return self:wwScale {min = 30, max = 70, stat = 'wil',}
	end,
	bite_damage = function(self, t)
		return self:wwScale {min = 0.6, max = 0.9, talent = t,}
	end,
	tactical = {BUFF = 2,},
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[The more you eat, the more your hunger grows. This will passively enhance your #UMBER#Swallow#LAST#, increasing the duration by %d. It will increase the maximum number of stacks by %d. You will now also get a %d%% #SLATE#[wil]#LAST# chance to deal an extra bite attack for %d%% weapon damage on each hit.
While active, whenever your #UMBER#Swallow#LAST# runs out of time, your equilibrium will increase by %d #SLATE#[str]#LAST# and your #UMBER#Swallow#LAST# will lose 1 stack and have its duration reset, provided you pass an equilibrium check.]])
			:format(get(t.duration, self, t),
							get(t.max_stacks, self, t),
							get(t.bite_chance, self, t),
							get(t.bite_damage, self, t) * 100,
							get(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Burrow', short_name = 'WEIRD_BURROW',
	type = {'wild-gift/sand-aspect', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 40,
	range = 0,
	cooldown = function(self, t) return 30 end,
	duration = function(self, t)
		return self:wwScale {min = 7, max = 20, talent = t, round = 'floor',}
	end,
	physcrit = function(self, t) return self:wwScale {min = 0, max = 12, talent = t,} end,
	tactical = {CLOSEIN = 2, KNOCKBACK = 1,},
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'combat_physcrit', get(t.physcrit, self ,t))
	end,
	action = function(self, t)
		self:setEffect('EFF_BURROW', get(t.duration, self, t), {})
		return true
	end,
	info = function(self, t)
		return ([[Upon activation, will allow you to burrow through walls for %d turns.
The sharpest of claws are needed to burrow - this will passively increase your physical critical chance by %d%%.]])
			:format(get(t.duration, self, t), get(t.physcrit, self, t))
	end,}

newTalent {
	name = 'Sand Aspect', short_name = 'WEIRD_SAND_ASPECT',
	type = {'wild-gift/sand-aspect', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	inc_damage = function(self, t)
		return self:wwScale {min = 5, max = 35, talent = t, stat = 'wil',} * 0.7
	end,
	resists_pen = function(self, t)
		return self:wwScale {min = 3, max = 10, talent = t,} * 0.7
	end,
	equilibrium_gain = function(self, t)
		return self:wwScale {min = 0.2, max = 2, talent = t,} * 0.7
	end,
	cooldown_reduce = function(self, t)
		return self:wwScale {min = 2, max = 9, talent = t, round = 'floor',}
	end,
	passives = function(self, t, p)
		self:effectTemporaryValue(
			p, 'equilibrium_on_damage', {PHYSICAL = get(t.equilibrium_gain, self, t),})
		self:effectTemporaryValue(
			p, 'inc_damage', {PHYSICAL = get(t.inc_damage, self, t),})
		self:effectTemporaryValue(
			p, 'resists_pen', {PHYSICAL = get(t.resists_pen, self, t),})
	end,
	callbackOnStatChange = function(self, t, stat, value)
		if stat == self.STAT_STR then self:updateTalentPassives(t) end
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate sand as a dragon would. You gain %d%% #SLATE#[wil]#LAST# to all physical damage done, and %d%% physical resistance piercing. You regain %.1f equilibrium on any turn in which you deal physical damage.
This also reduces the cooldown of Swallow by %d.
Points in this talent count double for the purposes of draconic form talents.]])
			:format(get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.cooldown_reduce, self, t))
	end,}

newTalent {
	name = 'Sand Claw', short_name = 'WEIRD_SAND_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 5,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_CLAW', 'shared_cooldown')
	end,
	damage = function(self, t) return self:wwScale {min = 1.0, max = 1.8, talent = t,} end,
	duration = function(self, t) return self:wwScale {min = 1, max = 6, talent = t,} end,
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

		local damage = get(t.damage, self, t)
		local duration = self:mindCrit(get(t.duration, self, t))
		if self:attackTarget(actor, 'PHYSICAL', damage, true) then
			if actor:canBe('blind') then
				actor:setEffect('EFF_BLINDED', duration, {apply_power = self:combatMindpower(),})
			end
		end

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% weapon physical damage, and attempt to #YELLOW#blind#LAST# #SLATE#[mind vs. phys, stun]#LAST# them for %d #SLATE#[mind crit]#LAST# turns.]])
			:format(get(t.damage, self, t) * 100,
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Sand Drake Aura', short_name = 'WEIRD_SAND_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 7,
	cooldown = function(self, t)
		return self:callTalent('T_WEIRD_DRACONIC_AURA', 'shared_cooldown')
	end,
	tactical = {ATTACKAREA = 2, DISABLE = {KNOCKBACK = 2,},},
	range = 0,
	radius = function(self, t) return self:wwScale {min = 2, max = 4.5, talent = t, round = 'floor'} end,
	damage = function(self, t)
		return self:wwScale {min = 0.8, max = 1.3, talent = t, scale = 'damage',}
	end,
	knockback = function(self, t)
		return self:wwScale {min = 3, max = 7, stat = 'str', round = 'ceil',}
	end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false, no_restrict = true,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	no_npc_use = true,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local damage = self:mindCrit(get(t.damage, self, t) * self:combatDamage())
		local knockback = get(t.knockback, self, t)
		self:project(tg, self.x, self.y, 'PHYSKNOCKBACK', {dam = damage, dist = knockback,})
		self:doQuake(tg, self.x, self.y)

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Slam your foot onto the ground, shaking the area around you in radius %d. Those caught in the area will be hit with %d physical damage #SLATE#[phys, mind crit]#LAST# and #LIGHT_UMBER#knocked back#LAST# %d #SLATE#[str]#LAST# tiles. This will randomly rearrange the terrain within the quake's radius.]])
			:format(get(t.radius, self, t),
							dd(self, 'PHYSICAL', get(t.damage, self, t) * self:combatDamage()),
							get(t.knockback, self, t))
	end,}

newTalent {
	name = 'Sand Breath', short_name = 'WEIRD_SAND_BREATH',
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
			min = 45, max = 450, talent = t, stat = 'str', scale = 'damage',}
	end,
	duration = function(self, t) return self:wwScale {min = 5, max = 8, stat = 'str',} end,
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
		local swallow = self:hasEffect('EFF_WEIRD_SWALLOW')
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			damage_type:get('PHYSICAL').projector(self, x, y, 'PHYSICAL', damage)

			if actor.dead then
				kills = kills + 1
				return
			end

			if actor:canBe('blind') then
				actor:setEffect('EFF_BLINDED', duration, {apply_power = self:combatPhysicalpower(),})
			end
		end
		self:project(tg, x, y, projector)

		if kills > 0 and armor then
			self:callEffect('EFF_WEIRD_SWALLOW', 'add_stacks', kills)
		end

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_earth', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img='sandwings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t)

		return true
	end,
	info = function(self, t)
		return ([[Breathe sand at your foes, doing %d #SLATE#[str]#LAST# physical damage #SLATE#[mind crit]#LAST# in a radius %d cone. It will try to #YELLOW#blind#LAST# #SLATE#[phys vs. phys, blind]#LAST# anything it hits for %d #SLATE#[str]#LAST# turns.
Every enemy killed in the initial blast will give you 1 stack of #UMBER#Swallow#LAST#, if you already have it.]])
			:format(dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.radius, self, t),
							get(t.duration, self, t))
	end,}
--]==]
