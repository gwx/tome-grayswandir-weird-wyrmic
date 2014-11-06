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

local talents = require 'engine.interface.ActorTalents'
local stats = require 'engine.interface.ActorStats'
local dd = talents.damDesc
local particles = require 'engine.Particles'

newEffect {
	name = 'WEIRD_BURNING_RAGE', image = 'talents/weird_raging_rush.png',
	desc = 'Burning Rage',
	long_desc = function(self, eff)
		local bonuses = ''
		if eff.temps.combat_mentalresist then
			bonuses = ('\nTarget also gets %d mental save, %d%% combat speed and %d%% confusion immunity.')
				:format(eff.temps.combat_mentalresist,
								eff.temps.combat_physspeed * 100,
								eff.temps.confusion_immune * 100)
		end
		return ([[Target is burning with rage, giving them %d extra #LIGHT_RED#fire burn#LAST# damage on melee hits but reducing sight radius by %d.%s]])
			:format(dd(eff.src, 'FIRE', eff.temps.melee_project.FIREBURN),
								-eff.temps.sight,
						 bonuses)
	end,
	type = 'mental',
	subtype = {stance = true, fire = true,},
	status = 'beneficial',
	parameters = {project = 10, sight = -5,},
	on_gain = function(self, eff)
		return '#Target# enters a #ORANGE#Burning Rage#LAST#!', '+Burning Rage'
	end,
	on_lose = function(self, eff)
		return '#Target# is no longer in a #ORANGE#Burning Rage#LAST#!', '-Burning Rage'
	end,
	activate = function(self, eff)
		self:autoTemporaryValues(eff)
	end,
	on_timeout = function(self, eff)
		if self:isTalentActive 'T_WEIRD_FOCUSED_FURY' then
			local equilibrium = self:callTalent('T_WEIRD_FOCUSED_FURY', 'equilibrium_cost')
			local threshold = self:callTalent('T_WEIRD_FOCUSED_FURY', 'life_percent') * self.max_life
			if (eff.damage_taken or 0) >= threshold then
				self:incEquilibrium(equilibrium)
				if self:equilibriumChance() then
					eff.dur = eff.dur + 1
				else
					self:forceUseTalent('T_WEIRD_FOCUSED_FURY', {no_energy = true,})
				end
			end
		end
		eff.damage_taken = 0
	end,}

newEffect {
	name = 'WEIRD_FROZEN_ARMOUR',
	desc = 'Frozen Armour',
	long_desc = function(self, eff)
		return ([[Currently at %d stacks out of %d. Target gains %d armour and %d cold retaliation damage.
Target will lose a stack whenever they move, or 2 if currently at 4 or more stacks.]])
			:format(eff.stacks,
							eff.max_stacks,
							eff.combat_armor * eff.stacks,
							dd(self, 'COLD', eff.retaliation * eff.stacks))
	end,
	type = 'physical',
	subtype = {stance = true, cold = true,},
	status = 'beneficial',
	charges = function(self, eff) return eff.stacks end,
	parameters = {stacks = 1,
								max_stacks = 5,
								combat_armor = 3,
								retaliation = 5,},
	on_gain = function(self, eff)
		return '#Target# is encased in Frozen Armour!', '+Frozen Armour'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s Frozen Armour has broken!', '-Frozen Armour'
	end,
	decrease = 0, no_remove = true,
	damage_feedback = function(self, eff, src, value)
		if self:knowTalent 'T_WEIRD_RIGID_BODY' then
			local power = self:callTalent('T_WEIRD_RIGID_BODY', 'retaliation_percent')
			power = power * 100 * value / self.max_life
			if rng.percent(power) then
				local duration = self:callTalent('T_WEIRD_RIGID_BODY', 'duration')
				game.logSeen(self, ('%s tries to freeze their assailant!'):format(self.name:capitalize()))
				if src.canBe and src:canBe('stun') then
					src:setEffect('EFF_FROZEN', duration, {apply_power = self:combatMindpower(),})
					game.logSeen(src, ('%s is frozen cold!'):format(src.name:capitalize()))
				else
					game.logSeen(src, ('%s resists the freezing cold!'):format(src.name:capitalize()))
				end
			end
		end
	end,
	callbackOnMove = function(self, eff, moved, force, ox, oy)
		if ox ~= self.x or oy ~= self.y then
			self:autoTemporaryValuesRemove(eff)

			eff.moved = true
			if eff.stacks >= 4 then
				eff.stacks = eff.stacks - 2
			else
				eff.stacks = eff.stacks - 1
			end
			if eff.stacks <= 0 then
				self:removeEffect('EFF_WEIRD_FROZEN_ARMOUR', false, true)
			else
				self.tempeffect_def.EFF_WEIRD_FROZEN_ARMOUR.activate(self, eff)
			end
		end
	end,
	add_stacks = function(self, eff, stacks)
		self:autoTemporaryValuesRemove(eff)
		eff.stacks = eff.stacks + stacks
		self.tempeffect_def.EFF_WEIRD_FROZEN_ARMOUR.activate(self, eff)
	end,
	activate = function(self, eff)
		if eff.stacks > eff.max_stacks then eff.stacks = eff.max_stacks end
		self:effectTemporaryValue(eff, 'combat_armor', eff.combat_armor * eff.stacks)
		self:effectTemporaryValue(eff, 'on_melee_hit', {COLD = eff.retaliation * eff.stacks,})
		self.bonuses = {}
		for stat, amount in pairs(self.frozen_armour_bonuses or {}) do
			self.bonuses.stat = amount
			self:effectTemporaryValue(eff, stat, amount)
		end
	end,
	on_merge = function(self, old, new)
		self:autoTemporaryValuesRemove(old)
		new.max_stacks = math.max(old.max_stacks, new.max_stacks)
		new.stacks = old.stacks + new.stacks
		self.tempeffect_def.EFF_WEIRD_FROZEN_ARMOUR.activate(self, new)
		return new
	end,
	on_timeout = function(self, eff)
		if self:isTalentActive('T_WEIRD_RIGID_BODY') then
			local equilibrium = self:callTalent('T_WEIRD_RIGID_BODY', 'equilibrium_cost')
			if not eff.moved and eff.stacks < eff.max_stacks then
				self:incEquilibrium(equilibrium)
				if self:equilibriumChance() then
					self:callEffect('EFF_WEIRD_FROZEN_ARMOUR', 'add_stacks', 1)
				else
					self:forceUseTalent('T_WEIRD_RIGID_BODY', {no_energy = true,})
				end
			end
		end
		eff.moved = nil
	end,}

newEffect {
	name = 'WEIRD_LIGHTNING_SPEED', image = 'talents/weird_lightning_speed.png',
	desc = 'Lightning Speed',
	long_desc = function(self, eff)
		local daze = ''
		if eff.daze > 0 then
			daze = ('\nAll #ROYAL_BLUE#lightning#LAST# damage you do will #VIOLET#daze#LAST# #SLATE#[mind vs. phys, stun]#LAST# for %d turns.')
				:format(eff.daze)
		end
		return ([[Target is moving incredibly quickly, giving them %d%% extra movement speed and %d%% evasion chance.%s]])
			:format(eff.speed * 100, eff.evasion, daze)
	end,
	type = 'physical',
	subtype = {speed = true, lightning = true, nature = true,},
	status = 'beneficial',
	parameters = {speed = 1, evasion = 30, daze = 0,},
	on_gain = function(self, eff)
		return '#Target# speeds up!', '+Lightning Speed'
	end,
	on_lose = function(self, eff)
		return '#Target# slows down!', '-Lightning Speed'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'lightning_speed', 1)
		self:effectTemporaryValue(eff, 'movement_speed', eff.speed)
		self:effectTemporaryValue(eff, 'evasion', eff.evasion)
		self:effectTemporaryValue(eff, 'weird_lightning_daze', eff.daze)
	end,}

newEffect {
	name = 'WEIRD_RAPID_STRIKES', image = 'talents/weird_rapid_strikes.png',
	desc = 'Rapid Strikes',
	long_desc = function(self, eff)
		return ('Target gains %d #ROYAL_BLUE#lightning#LAST# damage on hit and %d%% combat speed. This effect ends whenever the target takes an action that does not result in %s taking #ROYAL_BLUE#lightning#LAST# damage.')
		:format(dd(self, 'LIGHTNING', eff.project),
						eff.speed * 100,
						eff.target.name)
	end,
	type = 'physical',
	subtype = {speed = true, lightning = true, stance = true,},
	decrease = 0, no_remove = true,
	status = 'beneficial',
	parameters = {speed = 0.1, project = 10,},
	on_gain = function(self, eff)
		return ('#Target# begins to strike %s rapidly!'):format(eff.target.name), '+Rapid Strikes'
	end,
	on_lose = function(self, eff)
		return ('#Target# stops rapidly striking %s!'):format(eff.target.name), '-Rapid Strikes'
	end,
	callbackOnAct = function(self, eff)
		if eff.damage_done then
			eff.damage_done = false
		else
			self:removeEffect('EFF_WEIRD_RAPID_STRIKES', false, true)
		end
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_physspeed', eff.speed)
		self:effectTemporaryValue(eff, 'melee_project', {LIGHTNING = eff.project,})
		eff.damage_done = true
	end,}

newEffect {
	name = 'WEIRD_PURE_LIGHTNING',
	desc = 'Pure Lightning',
	long_desc = function(self, eff)
		return 'Once per turn, when hit you will avoid the damage and move to an adjacent square.'
	end,
	type = 'physical',
	subtype = {speed = true, lightning = true,},
	status = 'beneficial',
	parameters = {},
	on_gain = function(self, eff)
		return '#Target# turns into #ROYAL_BLUE#Pure Lightning#LAST#!', '+Pure Lightning'
	end,
	on_lose = function(self, eff)
		return '#Target# is no longer #ROYAL_BLUE#Pure Lightning#LAST#!', '-Pure Lightning'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'phase_shift', 1)
	end,}

newEffect {
	name = 'WEIRD_APPETITE',
	desc = 'Appetite',
	long_desc = function(self, eff)
		return ([[Currently at %d stacks out of %d. Each stack will last for %d turns. Target gains %d physical power, %d%% healing modifier, and %.2f equilibrium regeneration. When the timer runs out, a single stack will be lost.]])
			:format(eff.stacks,
							eff.max_stacks,
							eff.original_duration,
							eff.power * eff.stacks,
							eff.healmod * eff.stacks,
							eff.equi_regen * eff.stacks)
	end,
	type = 'physical',
	subtype = {nature = true, drake = true,},
	status = 'beneficial',
	charges = function(self, eff) return eff.stacks end,
	parameters = {stacks = 1,
								max_stacks = 5,
								strength = 1,
								combat_physresist = 1,},
	add_stacks = function(self, eff, stacks)
		if eff.__tmpvals then
			for i = 1, #eff.__tmpvals do
				self:removeTemporaryValue(eff.__tmpvals[i][1], eff.__tmpvals[i][2])
			end
		end

		eff.stacks = eff.stacks + stacks
		self.tempeffect_def.EFF_WEIRD_APPETITE.activate(self, eff)
	end,
	activate = function(self, eff)
		if eff.stacks > eff.max_stacks then eff.stacks = eff.max_stacks end
		self:effectTemporaryValue(eff, 'combat_dam', eff.power * eff.stacks)
		self:effectTemporaryValue(eff, 'healing_factor', eff.healmod * 0.01 * eff.stacks)
		self:effectTemporaryValue(eff, 'equilibrium_regen', -eff.equi_regen * eff.stacks)
	end,
	deactivate = function(self, eff)
		eff.__tmpvals = nil
		eff.stacks = eff.stacks - 1
		if eff.stacks == 0 then return end
		local later = function() self:setEffect('EFF_WEIRD_APPETITE', eff.original_duration, eff) end
		game:onTickEnd(later)
	end,
	on_merge = function(self, old, new)
		if old.__tmpvals then
			for i = 1, #old.__tmpvals do
				self:removeTemporaryValue(old.__tmpvals[i][1], old.__tmpvals[i][2])
			end
		end

		new.max_stacks = math.max(old.stacks, new.max_stacks)
		new.stacks = math.min(new.max_stacks, old.stacks + new.stacks)
		self.tempeffect_def.EFF_WEIRD_APPETITE.activate(self, new)
		return new
	end,}

newEffect {
	name = 'WEIRD_SAND_BARRIER', image = 'talents/weird_sandblaster.png',
	desc = 'Sand Barrier',
	long_desc = function(self, eff)
		return ([[Target gains %d defense and %d%% physical resistance.]])
			:format(eff.defense, eff.resist)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
	status = 'beneficial',
	parameters = {defense = 10, resist = 10,},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_def', eff.defense)
		self:effectTemporaryValue(eff, 'resists', {PHYSICAL = eff.resist,})
		eff.particle = self:addParticles(particles.new('sandy_shield', 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
	end,}

newEffect {
	name = 'WEIRD_PARTIALLY_BLINDED',
	desc = 'Partially Blinded',
	long_desc = function(self, eff)
		return ([[Target is #GREY#partially blinded#LAST#, reducing accuracy by %d.]])
			:format(eff.accuracy)
	end,
	type = 'physical',
	subtype = {earth = true, blind = true,},
	status = 'detrimental',
	parameters = {accuracy = 10,},
	on_gain = function(self, eff)
		return '#Target# is #GREY#Partially Blinded#LAST#!', '+Partially Blinded'
	end,
	on_lose = function(self, eff)
		return '#Target# is no longer #GRE#Partially Blinded#LAST#.', '-Partially Blinded'
	end,
	activate = function(self, eff)
		-- If target is already blinded, instead increase the duration up to ours.
		local blind = self:hasEffect('EFF_BLINDED')
		if blind then
			blind.dur = math.max(blind.dur, eff.dur)
			self:removeEffect('EFF_WEIRD_PARTIALLY_BLINDED')
			return
		end

		local immune = self.blind_immune or 0
		if immune >= 1 then
			self:removeEffect('EFF_WEIRD_PARTIALLY_BLINDED')
			return
		end

		self:effectTemporaryValue(eff, 'combat_atk', -eff.accuracy * (1 - immune))
	end,}

newEffect {
	name = 'WEIRD_SAND_BARRIER', image = 'talents/weird_sandblaster.png',
	desc = 'Sand Barrier',
	long_desc = function(self, eff)
		return ([[Target gains %d defense and %d%% physical resistance.]])
			:format(eff.defense, eff.resist)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
	status = 'beneficial',
	parameters = {defense = 10, resist = 10,},
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'combat_def', eff.defense)
		self:effectTemporaryValue(eff, 'resists', {PHYSICAL = eff.resist,})
		eff.particle = self:addParticles(particles.new('sandy_shield', 1))
	end,
	deactivate = function(self, eff)
		self:removeParticles(eff.particle)
	end,}

newEffect {
	name = 'WEIRD_ARMOR_REND', image = 'talents/weird_rending_claws.png',
	desc = 'Rent Armour',
	long_desc = function(self, eff)
		return ([[Target has their armour rent, decreasing it by %d.]])
			:format(eff.armor)
	end,
	type = 'physical',
	subtype = {earth = true, blind = true,},
	status = 'detrimental',
	parameters = {accuracy = 10,},
	on_gain = function(self, eff)
		return '#Target# has their armour rent!', '+Rent Armour'
	end,
	on_lose = function(self, eff)
		return '#Target# no longer has their armour rent.', '-Rent Armour'
	end,
	activate = function(self, eff)
		eff.armor = math.min(eff.armor_per, eff.armor_max)
		eff.armor_id = self:addTemporaryValue('combat_armor', -eff.armor)
	end,
	deactivate = function(self, eff)
		self:removeTemporaryValue('combat_armor', eff.armor_id)
	end,
	on_merge = function(self, old, new)
		self:removeTemporaryValue('combat_armor', old.armor_id)
		new.dur = math.max(old.dur, new.dur)
		new.armor = math.max(
			old.armor,
			math.min(new.armor_max, old.armor + new.armor_per))
		new.armor_id = self:addTemporaryValue('combat_armor', -new.armor)
		return new
	end,}

newEffect {
	name = 'WEIRD_WOUNDING_BLOWS', image = 'talents/weird_great_slash.png',
	desc = 'Wounding Blows',
	long_desc = function(self, eff)
		return ([[Target's melee attacks hava %d%% chance to inflict a #FF3333#Great Wound#LAST#, reducing constitution by %d and physical resistance by %d%% for %d turns.]])
			:format(eff.chance, eff.con, eff.resist, eff.duration)
	end,
	type = 'physical',
	subtype = {nature = true, tactic = true,},
	status = 'beneficial',
	parameters = {chance = 10, con = 10, resist = 10, duration = 4,},
	activate = function(self, eff) end,
	deactivate = function(self, eff) end,
	callbackOnMeleeAttack = function(self, eff, actor, hitted, crit, weapon, damtype, mult, dam)
		if not hitted or actor.dead then return end
		if not actor:canBe 'cut' then return end
		if not rng.percent(eff.chance) then return end
		actor:setEffect('EFF_WEIRD_GREAT_WOUND', eff.duration, {
											src = self,
											apply_power = self:combatPhysicalpower(),
											con = eff.con,
											resist = eff.resist,})
	end,}

newEffect {
	name = 'WEIRD_GREAT_WOUND',
	desc = 'Great Wound',
	long_desc = function(self, eff)
		return ([[Target has a great wound, reducing constitution by %d and physical resistance by %d%%.]])
			:format(eff.con, eff.resist)
	end,
	type = 'physical',
	subtype = {cut = true, wound = true,},
	status = 'detrimental',
	parameters = {con = 10, resist = 10,},
	on_gain = function(self, eff)
		return '#Target# has received a #FF3333#Great Wound#LAST#!', '+Great Wound'
	end,
	on_lose = function(self, eff)
		return '#Target# has healed the #FF3333#Great Wound#LAST#!', '-Great Wound'
	end,
	activate = function(self, eff)
		self:autoTemporaryValues(
			eff, {
				inc_stats = {[stats.STAT_CON] = -eff.con,},
				resists = {PHYSICAL = -eff.resist,},})
	end,
	deactivate = function(self, eff) end,}

newEffect {
	name = 'WEIRD_IMPALED',
	desc = 'Impaled',
	long_desc = function(self, eff)
		local msg = ''
		if eff.is_pin then
			msg = msg .. ' pinning it'
			if eff.is_wound then msg = msg .. ' and' end
		end
		if eff.is_wound then
			msg = msg .. (' dealing %d physical damage every turn'):format(eff.damage)
		end
		return ([[Target has been impaled with a large spike,%s.]]):format(msg)
	end,
	type = 'physical',
	subtype = {wound = true, pin = true,},
	status = 'detrimental',
	parameters = {damage = 10,},
	on_gain = function(self, eff)
		return '#Target# has been #CCCCFF#Impaled#LAST#!', '+Impaled'
	end,
	on_lose = function(self, eff)
		return '#Target# is no longer #CCCCFF#Impaled#LAST#!', '-Impaled'
	end,
	activate = function(self, eff)
		local count = 0
		if self:canBe 'pin' then
			self:effectTemporaryValue(eff, 'never_move', 1)
			eff.is_pin = true
			count = count + 1
		end
		if self:canBe 'cut' then
			eff.is_wound = true
			count = count + 1
		end
		if count == 0 then self:removeEffect 'EFF_WEIRD_IMPALED' end
	end,
	deactivate = function(self, eff) end,
	on_timeout = function(self, eff)
		if eff.src and eff.is_wound then
			eff.src:projectOn(self, 'PHYSICAL', eff.damage)
		end
	end,}

newEffect{
	name = 'WEIRD_PETRIFIED', image = 'talents/stone_touch.png',
	desc = 'Petrified',
	long_desc = function(self, eff) return 'The target has been turned to stone, making it subject to shattering but improving physical(+20%), fire(+80%) and lightning(+50%) resistances.' end,
	type = 'physical',
	subtype = {earth = true, stone = true,},
	status = 'detrimental',
	parameters = {},
	on_gain = function(self, err) return '#Target# is #BBBBBB#Petrified#LAST#!', '+Petrified' end,
	on_lose = function(self, err) return '#Target# is no longer #BBBBBB#Petrified#LAST#.', '-Petrified' end,
	activate = function(self, eff)
		self:autoTemporaryValues(
			eff, {
				stoned = 1,
				resists = {FIRE = 80, LIGHTNING = 50, PHYSICAL = 20,},})
	end,
	deactivate = function(self, eff) end,}

local blocking = TemporaryEffects.tempeffect_def.EFF_BLOCKING
local do_block = blocking.do_block
blocking.do_block = function(type, dam, eff, self, src)
	self.block_done = true
	return do_block(type, dam, eff, self, src)
end
