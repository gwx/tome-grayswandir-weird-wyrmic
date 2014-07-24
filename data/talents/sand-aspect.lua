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
	cooldown = 12,
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 0.9, high = 1.4, t,} end,
	project = function(self, t) return self:scale {low = 10, high = 80, 'phys', after = 'damage',} end,
	buff_duration = function(self, t)
		local duration = 6
		if self:knowTalent('T_WEIRD_BURROW') then
			duration = duration + self:callTalent('T_WEIRD_BURROW', 'barrier_duration')
		end
		return duration
	end,
	no_energy = 'fake',
	defense = function(self, t) return self:scale {low = 5, high = 30, t, 'phys',} end,
	resist = function(self, t) return self:scale {low = 0, high = 22, t, 'phys',} end,
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

		local hits = 0
		if actor then
			self:attackTarget(actor, 'PHYSICAL', get(t.weapon_mult, self, t))
			hits = hits + 1
		end

		local project = get(t.project, self, t)
		local dir = util.getDir(x, y, self.x, self.y)
		local sides = util.dirSides(dir)
		for _, dir in pairs {5, sides.left, dir, sides.right} do
			local x2, y2 = util.coordAddDir(x, y, dir)
			local actor = game.level.map(x2, y2, map.ACTOR)
			if actor then
				hits = hits + 1
				damage_type:get('PHYSICAL').projector(self, x2, y2, 'PHYSICAL', project)
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
		return ([[Powerfully swing your weapon into the ground and then into an adjacent target for %d%% #SLATE#[*]#LAST# weapon physical damage. This will kick up sand, hitting the target and the 3 spaces behind it for %d #SLATE#[* phys]#LAST# physical damage.
If you hit anything, the kicked up sand will form a #LIGHT_UMBER#Sand Barrier#LAST# around you, giving you %d #SLATE#[*, phys]#LAST# defense and %d%% #SLATE#[*, phys]#LAST# physical resistance for %d turns.]])
			:format(get(t.weapon_mult, self, t) * 100,
							dd(self, 'PHYSICAL', get(t.project, self, t)),
							get(t.defense, self, t),
							get(t.resist, self, t),
							get(t.buff_duration, self, t))
	end,}

newTalent {
	name = 'Burrow', short_name = 'WEIRD_BURROW',
	type = {'wild-gift/sand-aspect', 2,},
	require = make_require(2),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 12,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	sustain_equilibrium = 20,
	equilibrium_cost = function(self, t)
		return self:scale {low = 9, high = 6, limit = 3, t,}
	end,
	barrier_duration = function(self, t)
		return self:scale {low = 0, high = 6, t, after = 'floor'}
	end,
	activate = function(self, t)
		local p = {}
		self:talentTemporaryValue(p, 'can_pass', {pass_wall = 1,})
		self:talentTemporaryValue(
			p, 'move_project', {
				WEIRD_BURROW = {cost = get(t.equilibrium_cost, self, t),},})
		return p
	end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[While active you may burrow through diggable walls, costing you %.2f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# per wall. After burrowing, you must pass an #00FF74#equilibrium#LAST# check to keep this sustained.
This will also passively increase the duration of your #LIGHT_UMBER#Sand Barrier#LAST# by %d #SLATE#[*]#LAST#.]])
			:format(get(t.equilibrium_cost, self, t),
							get(t.barrier_duration, self, t))
	end,}

newTalent {
	name = 'Sand Vortex', short_name = 'WEIRD_SAND_VORTEX',
	type = {'wild-gift/sand-aspect', 3,},
	require = make_require(3),
	points = 5,
	equilibrium = 8,
	cooldown = 16,
	range = 0,
	is_mind = true,
	radius = function(self, t)
		return self:scale {low = 3, high = 7, limit = 10, t, after = 'floor',}
	end,
	project = function(self, t) return self:scale {low = 40, high = 350, t, 'phys', after = 'damage',} end,
	blind_duration = function(self, t) return self:scale {low = 3, high = 7, limit = 10, t, after = 'floor',} end,
	partial_blind = function(self, t) return self:scale {low = 10, high = 70, t, 'mind'} end,
	inflict_blind_param = function(self, t)
		return {duration = get(t.blind_duration, self, t),
						duration_scale = ' #SLATE#[*]#LAST#',
						accuracy = get(t.partial_blind, self, t),
						accuracy_scale = ' #SLATE#[*, mind]#LAST#',}
	end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local hits = 0
		local damage = self:mindCrit(get(t.project, self, t))
		local barrier = self:hasEffect('EFF_WEIRD_SAND_BARRIER')
		local blind_param = get(t.inflict_blind_param, self, t)
		local projector = function(x, y)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			hits = hits + 1
			damage_type:get('PHYSICAL').projector(self, x, y, 'PHYSICAL', damage)
			if barrier then self:inflict('blind', actor, blind_param) end
			actor:pull(self.x, self.y, core.fov.distance(self.x, self.y, actor.x, actor.y) - 1)
		end
		self:project(tg, self.x, self.y, projector)

		if hits > 0 and barrier then
			barrier.dur = math.max(barrier.dur, self:callTalent('T_WEIRD_SANDBLASTER', 'buff_duration'))
		end

		-- Sand Breath particles.
		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'weird_sandstorm', {radius = tg.radius})
		game:playSoundNear(self, 'talents/cloud')

		return true
	end,
	info = function(self, t)
		return ([[Create a vortex of sand around you in radius %d #SLATE#[*]#LAST#, pulling targets towards you, dealing %d #SLATE#[*, phys, mind crit]#LAST# physical damage. If your #LIGHT_UMBER#Sand Barrier#LAST# is active, then you will also %s
If you hit anything the duration of your #LIGHT_UMBER#Sand Barrier#LAST# will be reset to full.]])
			:format(get(t.radius, self, t),
							dd(self, 'PHYSICAL', get(t.project, self, t)),
							self:describeInflict('blind', get(t.inflict_blind_param, self, t)))
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
		return self:scale {low = 5, high = 25, t,} * 0.6
	end,
	resists_pen = function(self, t)
		return self:scale {low = 0, high = 12, t,} -- * 0.6
	end,
	equilibrium_gain = function(self, t)
		return self:scale {low = 0.2, high = 2, t,} * 0.6
	end,
	cooldown_mod = function(self, t)
		return self:scale {low = 100, high = 60, limit = 33, t}
	end,
	passives = function(self, t, p)
		self:autoTemporaryValues(
			p, {
				equilibrium_on_damage = {PHYSICAL = get(t.equilibrium_gain, self, t),},
				inc_damage = {PHYSICAL = get(t.inc_damage, self, t),},
				resists_pen = {PHYSICAL = get(t.resists_pen, self, t),},})
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate sand as a dragon would. You gain %d%% #SLATE#[*]#LAST# to all physical damage done, and %d%% #SLATE#[*]#LAST# physical resistance piercing. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you deal physical damage.
Points in this talent count double for the purposes of draconic form talents. All of your sand aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_SAND_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_SAND_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Sand Claw', short_name = 'WEIRD_SAND_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 5,
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
	duration = function(self, t) return self:scale {low = 2, high = 5, limit = 8, t,} end,
	accuracy = function(self, t) return self:scale {low = 10, high = 60, t, 'phys',} end,
	blind_param = function(self, t)
		return {duration = get(t.duration, self, t),
						duration_scale = ' #SLATE#[*, mind crit]#LAST#',
						accuracy = get(t.accuracy, self, t),
						accuracy_scale = ' #SLATE#[*, phys]#LAST#',}
	end,
	no_energy = 'fake',
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
		local duration = self:mindCrit(get(t.duration, self, t))
		if self:attackTarget(actor, 'PHYSICAL', weapon_mult) then
			self:inflict('blind', actor, get(t.blind_param, self, t))
		end

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% #SLATE#[*]#LAST# weapon physical damage, and %s]])
			:format(get(t.weapon_mult, self, t) * 100,
							self:describeInflict('blind', get(t.blind_param, self, t)))
	end,}

newTalent {
	name = 'Sand Drake Aura', short_name = 'WEIRD_SAND_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 7,
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
	tactical = {ATTACKAREA = 2, DISABLE = {KNOCKBACK = 2,},},
	range = 0,
	radius = function(self, t) return self:scale {low = 2, high = 4.5, t, after = 'floor'} end,
	damage = function(self, t)
		return self:scale {low = 0.8, high = 1.3, t, after = 'damage',}
	end,
	knockback = function(self, t)
		return self:scale {low = 3, high = 7, 'str', after = 'ceil',}
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

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

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
		return self:scale {low = 45, high = 450, t, 'phys', after = 'damage',}
	end,
	duration = function(self, t) return self:scale {low = 3, high = 6, limit = 9, t,} end,
	accuracy = function(self, t) return self:scale {low = 10, high = 70, t, 'phys',} end,
	blind_param = function(self, t)
		return {duration = get(t.duration, self, t),
						duration_scale = ' #SLATE#[*]#LAST#',
						accuracy = get(t.accuracy, self, t),
						accuracy_scale = ' #SLATE#[*, phys]#LAST#',}
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
		local blind_param = get(t.blind_param, self, t)
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end

			damage_type:get('PHYSICAL').projector(self, x, y, 'PHYSICAL', damage)
			self:inflict('blind', actor, blind_param)
		end
		self:project(tg, x, y, projector)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_earth', {
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
		return ([[Breathe sand at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# physical damage in a radius %d #SLATE#[*]#LASTE# cone. It will %s]])
			:format(dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.radius, self, t),
							self:describeInflict('blind', get(t.blind_param, self, t)))
	end,}
