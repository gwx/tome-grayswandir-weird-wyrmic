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
	type = 'wild-gift/blade-aspect',
	name = 'Blade Aspect',
	description = 'Channel the immense power of the blade drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {wil = function(level) return 12 + tier * 8 + level * 2 end,},
		level = function(level) return 5 + tier * 4 + level end,}
end

local two_hand_pre_use = function(self, t, silent)
	if not self:hasTwoHandedWeapon() and not self.innate_drake_talents then
		if not silent then
			game.logPlayer(self, 'You require a two-handed weapon to use this talent.')
		end
		return false
	end
	return true
end

newTalent {
	name = 'Great Slash', short_name = 'WEIRD_GREAT_SLASH',
	type = {'wild-gift/blade-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 5,
	cooldown = 12,
	no_energy = 'fake',
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 1.0, high = 1.7, t,} end,
	stun = function(self, t) return self:scale {low = 1, high = 3, limit = 5, t, after = 'ceil',} end,
	buff = 4,
	wound_chance = function(self, t) return self:scale {low = 10, high = 42, t,} end,
	wound_dur = 5,
	wound_con = function(self, t) return self:scale {low = 10, high = 50, 'phys',} end,
	wound_resist = function(self, t) return self:scale {low = 5, high = 25, 'phys',} end,
	tactical = {ATTACK = 2, DISABLE = 2, BUFF = 2,},
	requires_target = true,
	target = function(self, t) return {type = 'hit', talent = t, nowarning = true, range = get(t.range, self, t),} end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	on_pre_use = two_hand_pre_use,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local dir = util.getDir(x, y, self.x, self.y)
		if dir == 5 then return end

		local targets = {{x, y,}}
		table.insert(targets, {util.coordAddDir(self.x, self.y, util.dirSides(dir, self.x, self.y).left)})
		table.insert(targets, {util.coordAddDir(self.x, self.y, util.dirSides(dir, self.x, self.y).right)})

		local actors = {}
		for _, target in pairs(targets) do
			local actor = game.level.map(target[1], target[2], map.ACTOR)
			if actor then table.insert(actors, actor) end
		end
		if #actors == 0 then return end

		self:setEffect('EFF_WEIRD_WOUNDING_BLOWS', #actors * get(t.buff, self, t), {
										 chance = get(t.wound_chance, self, t),
										 duration = get(t.wound_duration, self, t),
										 con = get(t.wound_con, self, t),
										 resist = get(t.wound_resist, self, t),})

		local no_energy = false
		local weapon_mult = get(t.weapon_mult, self, t)
		local stun = get(t.stun, self, t)
		local apply_power = self:combatPhysicalpower()
		for _, actor in pairs(actors) do
			if self:attackTarget(actor, nil, weapon_mult, no_energy) then
				if actor:canBe('stun') then
					actor:setEffect('EFF_STUNNED', stun, {apply_power = apply_power,})
				end
			end
			no_energy = true
		end

		return true
	end,
	info = function(self, t)
		return ([[Swing your weapon in a great arc, striking three adjacent targets for %d%% #SLATE#[*]#LAST# weapon damage, attempting to #ORANGE#stun#LAST# #SLATE#[phys vs phys, stun]#LAST# them for %d #SLATE#[*]#LAST# turns.
You will gain the #CCCCCC#Wounding Blows#LAST# buff for %d turns per target, giving your melee attacks a %d%% #SLATE#[*]#LAST# chance to leave a #FF3333#Great Wound#LAST# #SLATE#[phys vs phys, cut]#LAST# on the target for %d turns, reducing its constitution by %d #SLATE#[phys]#LAST# and its physical resistance by %d%% #SLATE#[phys]#LAST#.
Requires a two-handed weapon to use.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.stun, self, t),
							get(t.buff, self, t),
							get(t.wound_chance, self, t),
							get(t.wound_dur, self, t),
							get(t.wound_con, self, t),
							get(t.wound_resist, self, t))
	end,}

newTalent {
	name = 'Tail Swipe', short_name = 'WEIRD_TAIL_SWIPE',
	type = {'wild-gift/blade-aspect', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 7,
	cooldown = function(self, t) return self:scale {low = 12, high = 7, limit = 4, t, after = 'ceil',} end,
	no_energy = true,
	range = 1,
	weapon_mult = function(self, t) return self:scale {low = 0.5, high = 0.9, t,} end,
	weapon_mult_wound = function(self, t) return self:scale {low = 0.2, high = 0.45, limit = 0.7, t,} end,
	tactical = {ATTACK = 2,},
	requires_target = true,
	target = function(self, t) return {type = 'hit', talent = t, range = get(t.range, self, t),} end,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	on_pre_use = two_hand_pre_use,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local wounds = actor:filterTemporaryEffects(function(effect, parameters) return effect.subtype.wound end)
		local weapon_mult = get(t.weapon_mult, self, t) + get(t.weapon_mult_wound, self, t) * #wounds
		self:attackTarget(actor, nil, weapon_mult, true)

		return true
	end,
	info = function(self, t)
		return ([[Perform a melee attack taking no energy. Deals %d%% #SLATE#[*]#LAST# weapon damage, plus an additional %d%% #SLATE#[*]#LAST# for every wound the target has.
Requires a two-handed weapon to use.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.weapon_mult_wound, self, t) * 100)
	end,}

newTalent {
	name = 'Razor Body', short_name = 'WEIRD_RAZOR_BODY',
	type = {'wild-gift/blade-aspect', 3,},
	require = make_require(3),
	points = 5,
	mode = 'sustained',
	sustain_equilibrium = 20,
	cooldown = 8,
	no_energy = true,
	equilibrium_cost = function(self, t)
		return self:scale {low = 1.0, high = 0.5, limit = 0.33, t,}
	end,
	wound_chance = function(self, t) return self:scale {low = 10, high = 30, limit = 50, t,} end,
	wound_dur = 4,
	wound_damage = function(self, t) return self:scale {low = 4, high = 40, t, 'phys', after = 'damage',} end,
	wound_heal_factor = function(self, t) return self:scale {low = 10, high = 40, t} end,
	retaliation = function(self, t) return self:scale {low = 4, high = 40, t, 'phys', after = 'damage',} end,
	tactical = {BUFF = 2,},
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	activate = function(self, t)
		local p = {}
		self:autoTemporaryValues(
			p, {
				on_melee_hit = {PHYSICAL = get(t.retaliation, self, t),},})
		p.wound_chance = get(t.wound_chance, self, t)
		p.wound_damage = get(t.wound_damage, self, t)
		p.wound_dur = get(t.wound_dur, self, t)
		p.wound_heal_factor = get(t.wound_heal_factor, self, t)
		return p
	end,
	deactivate = function(self, t, p) return true end,
	callbackOnMeleeHit = function(self, t, src, dam)
		local p = self.sustain_talents[t.id]
		if not rng.percent(p.wound_chance) then return end
		if not src:canBe 'cut' then return end
		src:setEffect('EFF_DEEP_WOUND', p.wound_dur, {
										src = self,
										apply_power = self:combatMindpower(),
										power = self:mindCrit(p.wound_damage),
										heal_factor = p.wound_heal_factor,})
		self:incEquilibrium(get(t.equilibrium_cost, self, t))
		if not self:equilibriumChance() then
			self:forceUseTalent('T_WEIRD_RAZOR_BODY', {no_energy = true,})
		end
	end,
	info = function(self, t)
		return ([[Your body is covered with razor shards, which give you %d #SLATE#[*, phys]#LAST# physical retaliation damage and a %d%% #SLATE#[*]#LAST# to inflict a #CC0000#Deep Wound#LAST# #SLATE#[mind vs phys, cut]#LAST# for %d turns when hit in melee, dealing %d #SLATE#[*, phys, mind crit]#LAST# physical damage per turn and reducing their healing factor by %d%% #SLATE#[*]#LAST#.
Every attempt to inflict a #CC0000#Deep Wound#LAST# will increase your #00FF74#equilibrium#LAST# by %.2f #SLATE#[*]#LAST# and you must pass an #00FF74#equilibrium#LAST# check, or this talent will deactivate.]])
			:format(dd(self, 'PHYSICAL', get(t.retaliation, self, t)),
							get(t.wound_chance, self, t),
							get(t.wound_dur, self, t),
							dd(self, 'PHYSICAL', get(t.wound_damage, self, t)),
							get(t.wound_heal_factor, self, t),
							get(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Blade Aspect', short_name = 'WEIRD_BLADE_ASPECT',
	type = {'wild-gift/blade-aspect', 4,},
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
		return self:scale {low = 0.2, high = 2, t,} * 2.5
	end,
	dammod_mult = function(self, t)
		return self:scale {low = 100, high = 300, limit = 400, t,}
	end,
	cooldown_mod = function(self, t)
		return self:scale {low = 100, high = 60, limit = 33, t}
	end,
	passives = function(self, t, p)
		self:autoTemporaryValues(
			p, {
				inc_wound_damage = get(t.inc_damage, self, t),
				dammod_str_100_mult = get(t.dammod_mult, self, t),})
	end,
	callbackOnInflictTemporaryEffect = function(self, t, eff_id, e, p)
		if e.subtype.wound then
			self:incEquilibrium(-get(t.equilibrium_gain, self, t))
			end end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate blades as a dragon would. You gain %d%% #SLATE#[*]#LAST# physical damage, and %d%% #SLATE#[*]#LAST# physical resistance piercing, for every wound a target has. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you inflict a wound. You treat all weapons as having the portion of their strength damage modifier over 100%% be %d%% #SLATE#[*]#LAST# as much #SLATE#(eg. 120%% -> %d%%#WHITE##SLATE#)#LAST#
Points in this talent count double for the purposes of draconic form talents. All of your blade aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.dammod_mult, self, t),
							get(t.dammod_mult, self, t) * 0.2 + 100,
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_BLADE_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_BLADE_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Blade Claw', short_name = 'WEIRD_BLADE_CLAW',
	type = {'wild-gift/draconic-claw', 1,}, hide = true,
	points = 5,
	equilibrium = 3,
	on_pre_use = two_hand_pre_use,
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
	weapon_mult = function(self, t) return self:scale {low = 2.0, high = 3.5, t,} end,
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

		self:attackTarget(actor, nil, get(t.weapon_mult, self, t))

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% #SLATE#[*]#LAST# weapon damage.
Requires a two-handed weapon to use.]])
			:format(get(t.weapon_mult, self, t) * 100)
	end,}

newTalent {
	name = 'Blade Drake Aura', short_name = 'WEIRD_BLADE_AURA',
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
	damage = function(self, t) return self:scale {low = 30, high = 120, t, 'phys', after = 'damage',} end,
	cripple_dur = 5,
	cripple_speed = function(self, t) return self:scale {low = 0.1, high = 0.3, limit = 0.5, t,} end,
	target = function(self, t)
		return {type = 'ball', talent = t, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local radius = get(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_matter', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/icestorm')

		local damage = self:mindCrit(get(t.damage, self, t))
		local cripple_dur = get(t.cripple_dur, self, t)
		local cripple_speed = get(t.cripple_speed, self, t)
		local apply_power = self:combatMindpower()
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor then return end
			self:projectOn(actor, 'PHYSICAL', damage)
			if not actor:canBe 'cut' then return end
			actor:setEffect('EFF_CRIPPLE', cripple_dur, {
												src = self,
												apply_power = apply_power,
												speed = cripple_speed,})
		end
		self:project(tg, self.x, self.y, projector)

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Release blades in radius %d #SLATE#[*]#LAST#, dealing %d #SLATE#[*, phys, mind crit]#LAST# physical damage and #RED#Crippling#LAST# #SLATE#[mind vs phys, cut]#LAST# them for %d turns, reducing their combat. spell. and mind speed by %d%% #SLATE#[*]#LAST#.]])
			:format(get(t.radius, self, t),
							dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.cripple_dur, self, t),
							get(t.cripple_speed, self ,t) * 100)
	end,}

newTalent {
	name = 'Blade Breath', short_name = 'WEIRD_BLADE_BREATH',
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
	impale_damage = function(self, t)
		return self:scale {low = 20, high = 90, t, 'phys', after = 'damage',}
	end,
	impale_dur = function(self, t) return self:scale {low = 5, high = 8, limit = 12, t, after = 'floor'} end,
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
		local apply_power = self:combatPhysicalpower()
		local impale_dur = get(t.impale_dur, self, t)
		local impale_damage = get(t.impale_damage, self, t)
		local kills = 0
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end
			self:projectOn(actor, 'PHYSICAL', damage)
			actor:setEffect('EFF_WEIRD_IMPALED', impale_dur, {
												src = self,
												apply_power = apply_power,
												damage = impale_damage,})
			if actor.dead then kills = kills + 1 end
		end
		self:project(tg, x, y, projector)

		self:alterTalentCoolingdown('T_WEIRD_GREAT_SLASH', -kills)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_blade', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		--[[
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img='life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end
		--]]

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Breathe blades at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# physical damage in a radius %d #SLATE#[*]#LAST# cone, attempting to #CCCCFF#Impale#LAST# #SLATE#[phys vs phys, bleed, pin]#LAST# those hit for %d #SLATE#[*]#LAST# turns, pinning them in place and dealing %d #SLATE#[*, phys]#LAST# physical damage per turn.
Every enemy killed in the initial blast will reduce the cooldown of Great Slash by 1.]])
			:format(dd(self, 'PHYSICAL', get(t.damage, self, t)),
							get(t.radius, self, t),
							get(t.impale_dur, self, t),
							dd(self, 'PHYSICAL', get(t.impale_damage, self ,t)))
	end,}
