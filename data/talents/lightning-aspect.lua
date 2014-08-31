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
	type = 'wild-gift/lightning-aspect',
	name = 'Lightning Aspect',
	description = 'Channel the lightning reflexes of the lightning drakes.',
	allow_random = true,}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

newTalent {
	name = 'Lightning Speed', short_name = 'WEIRD_LIGHTNING_SPEED',
	type = {'wild-gift/lightning-aspect', 1,},
	require = make_require(1),
	points = 5,
	equilibrium = 4,
	no_energy = true,
	cooldown = 16,
	speed = function(self, t) return self:scale {low = 2, high = 6, t,} end,
	duration = 2,
	evasion = function(self, t) return self:scale {low = 10, high = 35, t,} end,
	tactical = {CLOSEIN = 2, ESCAPE = 2,},
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local later = function()
			local duration = get(t.duration, self, t)
			local daze = 0
			if self:knowTalent('T_WEIRD_LIGHTNING_ASPECT') then
				daze = self:callTalent('T_WEIRD_LIGHTNING_ASPECT', 'daze_duration')
			end
			self:setEffect('EFF_WEIRD_LIGHTNING_SPEED', duration, {
											 speed = get(t.speed, self, t),
											 evasion = get(t.evasion, self, t),
											 daze = daze,})
		end
		game:onTickEnd(later)
		return true
	end,
	info = function(self, t)
		return ([[#38FF98#Speed up#LAST# gaining %d%% #SLATE#[*]#LAST# movement speed and %d%% #SLATE#[*]#LAST# evasion for %d turns.]])
			:format(get(t.speed, self, t) * 100,
							get(t.evasion, self, t),
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Rapid Strikes', short_name = 'WEIRD_RAPID_STRIKES',
	type = {'wild-gift/lightning-aspect', 2,},
	require = make_require(2),
	points = 5,
	equilibrium = 7,
	range = 1,
	no_energy = 'fake',
	cooldown = function(self, t)
		return self:scale {low = 8, high = 5, limit = 3, t, after = 'ceil',}
	end,
	weapon_mult = function(self, t)
		return self:scale {low = 1, high = 1.4, t,}
	end,
	damage = function(self, t)
		return self:scale {low = 5, high = 35, t, 'mind', after = 'damage',}
	end,
	speed = function(self, t)
		return self:scale {low = 0.1, high = 0.35, t,}
	end,
	tactical = {ATTACK = 1, BUFF = 1,},
	target = function(self, t)
		return {type = 'hit', talent = t, range = get(t.range, self, t),}
	end,
	requires_target = true,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	action = function(self, t)
		local tg = get(t.target, self, t)
		local x, y, actor = self:getTarget(tg)
		if not x or not y or not actor then return end
		if core.fov.distance(self.x, self.y, x, y) > tg.range then return end

		local weapon_mult = get(t.weapon_mult, self, t)
		self:setEffect('EFF_WEIRD_RAPID_STRIKES', 1, {
										 target = actor,
										 speed = get(t.speed, self, t),
										 project = get(t.damage, self, t),})
		self:attackTarget(actor, nil, weapon_mult)
		return true
	end,
	info = function(self, t)
		return ([[Hit an adjacent target with your weapon for %d%% #SLATE#[*]#LAST# damage. If this hits, you will gain %d #SLATE#[*, mind]#LAST# #ROYAL_BLUE#lightning#LAST# damage on hit and %d%% #SLATE#[*]#LAST# combat speed. You will lose this bonus when you take an action that does not result in the original target taking #ROYAL_BLUE#lightning#LAST# damage.]])
			:format(get(t.weapon_mult, self, t) * 100,
							dd(self, 'LIGHTNING', get(t.damage, self, t)),
							get(t.speed, self, t) * 100)
	end,}

newTalent {
	name = 'Jitter', short_name = 'WEIRD_JITTER',
	type = {'wild-gift/lightning-aspect', 3,},
	require = make_require(3),
	points = 5,
	mode = 'sustained',
	no_energy = true,
	cooldown = 8,
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	sustain_equilibrium = 20,
	equilibrium_cost = function(self, t)
		return self:scale {low = 2.5, high = 1.0, limit = 0.4, t,}
	end,
	dodge_percent = function(self, t)
		return self:scale {low = 0.5, high = 1.2, t,}
	end,
	dodge_duration = 2,
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
			self:incEquilibrium(get(t.equilibrium_cost, self, t))
		end
		p.moved = false
		p.damaged = false
	end,
	damage_feedback = function(self, t, p, src, value)
		if value > 0 then
			p.damaged = true
			local chance = get(t.dodge_percent, self, t)
			if rng.percent(chance * 100 * value / self.max_life) then
				if self:equilibriumChance() then
					local duration = self:mindCrit(get(t.dodge_duration, self, t))
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
		return ([[While active, whenever you take life damage, you have a chance equal to %.2f #SLATE#[*]#LAST# times the percentage of max life you lost to turn into #ROYAL_BLUE#Pure Lightning#LAST# for %d turns, completely dodging a single attack per turn by moving to an adjacent space. Trying to turn into #ROYAL_BLUE#Pure Lightning#LAST# will trigger an equilibrium check, deactivating this talent if you fail.
This will increase your #6FFF83#equilibrium#LAST# by %.2f on any game turn in which you take damage and did not move.]])
			:format(get(t.dodge_percent, self, t),
							math.floor(get(t.dodge_duration, self, t)),
							get(t.equilibrium_cost, self, t))
	end,}

newTalent {
	name = 'Lightning Aspect', short_name = 'WEIRD_LIGHTNING_ASPECT',
	type = {'wild-gift/lightning-aspect', 4,},
	require = make_require(4),
	points = 5,
	mode = 'passive',
	on_learn = Talents.recalc_draconic_form,
	on_unlearn = Talents.recalc_draconic_form,
	inc_damage = function(self, t)
		return self:scale {low = 5, high = 25, t, 'mind',}
	end,
	resists_pen = function(self, t)
		return self:scale {low = 0, high = 12, t,}
	end,
	equilibrium_gain = function(self, t)
		return self:scale {low = 0.2, high = 2, t,}
	end,
	daze_duration = function(self, t)
		return self:scale {low = 0, high = 3, limit = 5, t, after = 'floor',}
	end,
	cooldown_mod = function(self, t)
		return self:scale {low = 100, high = 60, limit = 33, t}
	end,
	passives = function(self, t, p)
		self:autoTemporaryValues(
			p, {
				equilibrium_on_damage = {LIGHTNING = get(t.equilibrium_gain, self, t),},
				inc_damage = {LIGHTNING = get(t.inc_damage, self, t),},
				resists_pen = {LIGHTNING = get(t.resists_pen, self, t),},})
	end,
	activate = function(self, t) return {} end,
	deactivate = function(self, t, p) return true end,
	info = function(self, t)
		return ([[You have mastered your ability to manipulate lightning as a dragon would. You gain %d%% #SLATE#[*]#LAST# to all #ROYAL_BLUE#lightning#LAST# damage done, and %d%% #SLATE#[*]#LAST# #ROYAL_BLUE#lightning#LAST# resistance piercing. You recover %.1f #SLATE#[*]#LAST# #00FF74#equilibrium#LAST# on any turn in which you deal #ROYAL_BLUE#lightning#LAST# damage.
While #38FF98#Lightning Speed#LAST# is active, all #ROYAL_BLUE#lightning#LAST# damage you do will #VIOLET#daze#LAST# #SLATE#[mind vs. phys, stun]#LAST# for %d #SLATE#[*]#LAST# turns.
Points in this talent count double for the purposes of draconic form talents. All of your lightning aspect draconic form talents set other elements on cooldown, and have their own cooldown set by other elements, by %d%% #SLATE#[*]#LAST# as much.]])
			:format(get(t.inc_damage, self, t),
							get(t.resists_pen, self, t),
							get(t.equilibrium_gain, self, t),
							get(t.daze_duration, self, t),
							get(t.cooldown_mod, self, t))
	end,}

local aspect_cooldown = function(self, t, cooldown)
	if self:knowTalent('T_WEIRD_LIGHTNING_ASPECT') then
		cooldown = math.ceil(cooldown * 0.01 * self:callTalent('T_WEIRD_LIGHTNING_ASPECT', 'cooldown_mod'))
	end
	return cooldown
end

newTalent {
	name = 'Lightning Claw', short_name = 'WEIRD_LIGHTNING_CLAW',
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
	weapon_mult = function(self, t) return self:scale {low = 1.0, high = 1.8, t,} end,
	duration = function(self, t) return self:scale {low = 2, high = 5, t, after = 'floor',} end,
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

		local weapon_mult = get(t.weapon_mult, self, t)
		local duration = get(t.duration, self, t)
		if self:attackTarget(actor, 'LIGHTNING', weapon_mult) then
			if actor:canBe('stun') then
				actor:setEffect('EFF_DAZED', duration, {apply_power = self:combatPhysicalpower(),})
			end
			game:playSoundNear(self, 'talents/lightning')
		end

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Hit the target for %d%% #SLATE#[*]#LAST# weapon #ROYAL_BLUE#lightning#LAST# damage, and attempt to #VIOLET#daze#LAST# #SLATE#[phys vs. phys, stun]#LAST# for %d #SLATE#[*]#LAST# turns.]])
			:format(get(t.weapon_mult, self, t) * 100,
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Lightning Drake Aura', short_name = 'WEIRD_LIGHTNING_AURA',
	type = {'wild-gift/draconic-aura', 1,}, hide = true,
	points = 5,
	equilibrium = 14,
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
		return self:scale {low = 30, high = 300, t, 'mind', after = 'damage',}
	end,
	duration = function(self, t) return self:scale {low = 2, high = 7, t, after = 'floor',} end,
	target = function(self, t)
		return {type = 'ball', talent = t, selffire = false, friendlyfire = false,
						range = get(t.range, self, t),
						radius = get(t.radius, self, t),}
	end,
	action = function(self, t)
		local tg = get(t.target, self, t)

		local radius = get(t.radius, self, t)
		game.level.map:particleEmitter(self.x, self.y, radius + 2, 'ball_lightning', {radius = radius + 2,})
		game:playSoundNear(self, 'talents/lightning')

		local damage = self:mindCrit(get(t.damage, self, t))
		local duration = get(t.duration, self, t)
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

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Produce a radius %d #SLATE#[*]#LAST# electric shock, dealing %d #SLATE#[*, mind]#LAST# #ROYAL_BLUE#lightning#LAST# damage and attempting to #VIOLET#daze#LAST# #SLATE#[mind vs phys, stun]#LAST# them for %d #SLATE#[*]#LAST# turns.]])
			:format(get(t.radius, self, t),
							dd(self, 'LIGHTNING', get(t.damage, self, t)),
							get(t.duration, self, t))
	end,}

newTalent {
	name = 'Lightning Breath', short_name = 'WEIRD_LIGHTNING_BREATH',
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
		return self:scale {low = 45, high = 450, t, 'phys', after = 'damage',}
	end,
	overkill = function(self, t)
		return self:scale {low = 40, high = 80, limit = 100, t,}
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

		-- grab targets
		local actors = {}
		local projector = function(x, y, tg, self)
			local actor = game.level.map(x, y, map.ACTOR)
			if not actor or actor.dead then return end
			table.insert(actors, actor)
		end
		self:project(tg, x, y, projector)

		local damage = self:mindCrit(get(t.damage, self, t))
		local overkill_mult = get(t.overkill, self, t) * 0.01
		local kills = 0
		while damage > 0 and #actors > 0 do
			local overkill = 0
			local to_del = {}
			for i, actor in pairs(actors) do
				self:projectOn(actor, 'LIGHTNING', damage)
				if actor.dead then
					kills = kills + 1
					overkill = overkill + actor.die_at - actor.life
					table.insert(to_del, i)
				end
			end
			for i = #to_del, 1, -1 do
				table.remove(actors, to_del[i])
			end
			damage = overkill * overkill_mult / #actors
		end

		self:alterTalentCoolingdown('T_WEIRD_LIGHTNING_SPEED', -kills)

		game.level.map:particleEmitter(self.x, self.y, tg.radius, 'breath_lightning', {
																		 radius = tg.radius,
																		 tx = x - self.x,
																		 ty = y - self.y,})
		if core.shader.active(4) then
			local bx, by = self:attachementSpot('back', true)
			self:addParticles(particles.new('shader_wings', 1, {img = 'lightningwings', life=18, x=bx, y=by, fade=-0.006, deploy_speed=14}))
		end

		game:playSoundNear(self, 'talents/breath')

		Talents.cooldown_group(self, t, get(t.group_cooldown, self, t))

		return true
	end,
	info = function(self, t)
		return ([[Breathe lightning at your foes, doing %d #SLATE#[*, phys, mind crit]#LAST# #ROYAL_BLUE#lightning#LAST# damage in a radius %d #SLATE#[*]#LAST# cone. %d%% #SLATE#[*]#LAST# of any overkill will be redistributed among the remaining targets.
Every enemy killed in the initial blast will reduce your #38FF98#Lightning Speed#LAST# cooldown by 1.]])
			:format(dd(self, 'LIGHTNING', get(t.damage, self, t)),
							get(t.radius, self, t),
							get(t.overkill, self, t))
	end,}
