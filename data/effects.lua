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


local talents = require 'engine.interface.ActorTalents'
local dd = talents.damDesc

newEffect {
	name = 'WEIRD_BURNING_RAGE', image = 'talents/weird_raging_rush.png',
	desc = 'Burning Rage',
	long_desc = function(self, eff)
		local bonuses = ''
		if eff.bonuses then
			bonuses = ('\nTarget also gets %d mental save, %d%% combat speed and %d%% confusion immunity.')
				:format(eff.bonuses.combat_mentalresist,
								eff.bonuses.combat_physspeed * 100,
								eff.bonuses.confusion_immune * 100)
		end
		return ([[Target is burning with rage, giving them %d extra #RED#fire#LAST# damage on melee hits but reducing sight radius by %d.%s]])
			:format(dd(eff.src, 'FIRE', eff.project),
								-eff.sight,
						 bonuses)
	end,
	type = 'mental',
	subtype = {stance = true, fire = true,},
	status = 'beneficial',
	parameters = {project = 10, sight = -5,},
	on_gain = function(self, eff)
		return '#Target# burns with rage!', '+Burning Rage'
	end,
	on_lose = function(self, eff)
		return '#Target# has cooled off!', '-Burning Rage'
	end,
	activate = function(self, eff)
		self:effectTemporaryValue(eff, 'sight', eff.sight)
		self:effectTemporaryValue(eff, 'melee_project', {FIRE = eff.fire,})
		self.bonuses = {}
		for stat, amount in pairs(self.burning_rage_bonuses or {}) do
			self.bonuses.stat = amount
			self:effectTemporaryValue(eff, stat, amount)
		end
	end,
	on_timeout = function(self, eff)
		if self:isTalentActive('T_WEIRD_FOCUSED_FURY') then
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
		local def = ''
		if eff.bonuses and eff.bonuses.combat_def then
			def = (', %d defense,'):format(eff.bonuses.combat_def * eff.stacks)
		end
		return ([[Currently at %d stacks out of %d. Target gains %d armour%s and %d cold retaliation damage.
Target will lose a stack whenever they move, or 2 if currently at 4 or more stacks.]])
			:format(eff.stacks,
							eff.max_stacks,
							eff.combat_armor * eff.stacks,
							def,
							dd(self, 'COLD', eff.retaliation * eff.stacks))
	end,
	type = 'physical',
	subtype = {stance = true, cold = true,},
	status = 'beneficial',
	charges = function(self, eff) return eff.stacks end,
	parameters = {stacks = 1,
								max_stacks = 5,
								combat_armor = 3,
								retaliation = 5,
								combat_def = 0,},
	on_gain = function(self, eff)
		return '#Target# is encased in Frozen Armour!', '+Frozen Armour'
	end,
	on_lose = function(self, eff)
		return '#Target#\'s Frozen Armour has broken!', '-Frozen Armour'
	end,
	decrease = 0, no_remove = true,
	damage_feedback = function(self, eff, src, value)
		if self:knowTalent('T_WEIRD_RIGID_BODY') then
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
			if eff.__tmpvals then
				for i = 1, #eff.__tmpvals do
					self:removeTemporaryValue(eff.__tmpvals[i][1], eff.__tmpvals[i][2])
				end
			end
			eff.__tmpvals = nil

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
		if eff.__tmpvals then
			for i = 1, #eff.__tmpvals do
				self:removeTemporaryValue(eff.__tmpvals[i][1], eff.__tmpvals[i][2])
			end
		end

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
		if old.__tmpvals then
			for i = 1, #old.__tmpvals do
				self:removeTemporaryValue(old.__tmpvals[i][1], old.__tmpvals[i][2])
			end
		end

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
		local msg = ''
		if not eff.is_low then
			msg = '\nAny action other than movement will break this effect.'
		end
		return ([[Target is moving incredibly quickly, giving them %d%% extra movement speed and %d%% evasion chance.%s]])
			:format(eff.speed * 100, eff.evasion, msg)
	end,
	type = 'physical',
	subtype = {speed = true, lightning = true, nature = true,},
	status = 'beneficial',
	parameters = {speed = 1, evasion = 30,},
	on_gain = function(self, eff)
		if not eff.is_low then
			return '#Target# speeds up!', '+Lightning Speed'
		end
	end,
	on_lose = function(self, eff)
		if not eff.is_low then
			return '#Target# slows down a little!'
		else
			return '#Target# slows down!', '-Lightning Speed'
		end
	end,
	callbackOnMove = function(self, eff, moved, force, ox, oy)
		if ox ~= self.x or oy ~= self.y then eff.moved = true end
	end,
	activate = function(self, eff)
		if eff.is_low then
			self:effectTemporaryValue(eff, 'movement_speed', eff.speed_low)
			self:effectTemporaryValue(eff, 'evasion', eff.evasion)
			eff.speed = eff.speed_low
		else
			self:effectTemporaryValue(eff, 'lightning_speed', 1)
			self:effectTemporaryValue(eff, 'movement_speed', eff.speed_high)
			self:effectTemporaryValue(eff, 'evasion', eff.evasion)
			eff.speed = eff.speed_high
		end
		self.bonuses = {}
		for stat, amount in pairs(self.lightning_speed_bonuses or {}) do
			self.bonuses.stat = amount
			self:effectTemporaryValue(eff, stat, amount)
		end
	end,
	deactivate = function(self, eff)
		if eff.is_low then return end
		eff.__tmpvals = nil
		eff.is_low = true
		local low = function() self:setEffect('EFF_WEIRD_LIGHTNING_SPEED', eff.duration_low, eff) end
		game:onTickEnd(low)
	end,
	damage_feedback = function(self, eff, src, value)
		if self:knowTalent('T_WEIRD_JITTER') then
			local power = self:callTalent('T_WEIRD_JITTER', 'dodge_percent')
			power = power * 100 * value / self.max_life
			if rng.percent(power) then
				local duration = self:callTalent('T_WEIRD_JITTER', 'dodge_duration')
				game:playSoundNear(self, 'talents/lightning')
				local later = function() self:setEffect('EFF_WEIRD_PURE_LIGHTNING', duration, {}) end
				game:onTickEnd(later)
			end
		end
	end,
	on_timeout = function(self, eff)
		if eff.is_low and self:isTalentActive('T_WEIRD_JITTER') then
			if eff.moved and eff.dur < self:callTalent('T_WEIRD_JITTER', 'max_duration') then
				local equilibrium = self:callTalent('T_WEIRD_JITTER', 'equilibrium_cost')
				self:incEquilibrium(equilibrium)
				if self:equilibriumChance() then
					eff.dur = eff.dur + 2
				else
					self:forceUseTalent('T_WEIRD_JITTER', {no_energy = true,})
				end
			end
		end
		eff.moved = nil
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
	name = 'WEIRD_SWALLOW', image = 'talents/weird_swallow.png',
	desc = 'Swallow',
	long_desc = function(self, eff)
		return ([[Currently at %d stacks out of %d. Target gains %d strength and %d physical save.]])
			:format(eff.stacks,
							eff.max_stacks,
							eff.strength * eff.stacks,
							eff.combat_physresist * eff.stacks)
	end,
	type = 'physical',
	subtype = {nature = true, earth = true,},
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
		self.tempeffect_def.EFF_WEIRD_SWALLOW.activate(self, eff)
	end,
	activate = function(self, eff)
		if eff.stacks > eff.max_stacks then eff.stacks = eff.max_stacks end
		self:effectTemporaryValue(eff, 'inc_stats', {[self.STAT_STR] = eff.strength,})
		self:effectTemporaryValue(eff, 'combat_physresist', eff.combat_physresist)
		self.bonuses = {}
		for stat, amount in pairs(self.swallow_bonuses or {}) do
			self.bonuses.stat = amount
			self:effectTemporaryValue(eff, stat, amount * eff.stacks)
		end
	end,
	deactivate = function(self, eff)
		eff.__tmpvals = nil
		if self:isTalentActive('T_WEIRD_APPETITE') then
			eff.stacks = eff.stacks - 1
			if eff.stacks == 0 then return end
			local equilibrium = self:callTalent('T_WEIRD_APPETITE', 'equilibrium_cost')
			self:incEquilibrium(equilibrium)
			if self:equilibriumChance() then
				local duration = self:callTalent('T_WEIRD_SWALLOW', 'duration')
				local later = function() self:setEffect('EFF_WEIRD_SWALLOW', duration, eff) end
				game:onTickEnd(later)
			else
				self:forceUseTalent('T_WEIRD_APPETITE', {no_energy = true,})
			end
		end
	end,
	on_merge = function(self, old, new)
		if old.__tmpvals then
			for i = 1, #old.__tmpvals do
				self:removeTemporaryValue(old.__tmpvals[i][1], old.__tmpvals[i][2])
			end
		end

		new.max_stacks = math.max(old.max_stacks, new.max_stacks)
		new.stacks = old.stacks + new.stacks
		self.tempeffect_def.EFF_WEIRD_SWALLOW.activate(self, new)
		return new
	end,}
