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


newInflict {
	name = 'stun',
	desc = function(parameters, tense)
		return ('#ORANGE#%s#LAST# #SLATE#[phys vs phys, stun]#LAST# for %d%s turns')
			:format((tense == 'progressive' and 'Stunning') or
								(tense == 'future' and 'Stunned') or
								'Stun',
							parameters.duration,
							parameters.duration_scale or '')
	end,
	action = function(self, target, parameters)
		local stun = false
		if target:canBe 'stun' then
			stun = self:inflictEffect(target, 'STUNNED', parameters.duration)
		end
		if not stun then
			game.logSeen(target, '%s resists being #Orange#Stunned#LAST#!', target.name:capitalize())
		end
	end,}

newInflict {
	name = 'daze',
	desc = function(parameters, tense)
		return ('#ORANGE#%s#LAST# #SLATE#[phys vs phys, stun]#LAST# for %d%s turns')
			:format((tense == 'progressive' and 'Dazing') or
								(tense == 'future' and 'Dazed') or
								'Daze',
							parameters.duration,
							parameters.duration_scale or '')
	end,
	action = function(self, target, parameters)
		local daze = false
		if target:canBe 'stun' then
			daze = self:inflictEffect(target, 'DAZED', parameters.duration)
		end
		if not daze then
			game.logSeen(target, '%s resists being #Orange#Dazed#LAST#!', target.name:capitalize())
		end
	end,}

newInflict {
	name = 'pin',
	desc = function(parameters, tense)
		return ('#LIGHT_UMBER#%s#LAST# #SLATE#[phys vs phys, pin]#LAST# for %d%s turns')
			:format((tense == 'progressive' and 'Pinning') or
								(tense == 'future' and 'Pinned') or
								'Pin',
							parameters.duration,
							parameters.duration_scale or '')
	end,
	action = function(self, target, parameters)
		local pin = false
		if target:canBe 'pin' then
			pin = self:inflictEffect(target, 'PINNED', parameters.duration)
		end
		if not pin then
			game.logSeen(target, '%s resists being #LIGHT_UMBER#Pinned#LAST#!', target.name:capitalize())
		end
	end,}

newInflict {
	name = 'petrify',
	desc = function(parameters, tense)
		return ('#BBBBBB#%s#LAST# #SLATE#[phys vs phys, stone, instakill]#LAST# for %d%s turns. Petrification prevents you from acting or healing and gives the following resistances: 80%% #LIGHT_RED#fire#LAST#, 50%% #ROYAL_BLUE#lightning#LAST#, 20%% physical. Being hit for 30%% of your max life while petrified will shatter and kill you.')
			:format((tense == 'progressive' and 'Perifying') or
								(tense == 'future' and 'Petrified') or
								'Petrify',
							parameters.duration,
							parameters.duration_scale or '')
	end,
	action = function(self, target, parameters)
		local apply = false
		if target:canBe 'stone' and target:canBe 'instakill' then
			apply = self:inflictEffect(target, 'WEIRD_PETRIFIED', parameters.duration)
		end
		if not apply then
			game.logSeen(target, '%s resists being #BBBBBB#Petrified#LAST#!', target.name:capitalize())
		end
	end,}

newInflict {
	name = 'knockback',
	desc = function(parameters)
		return ('#LIGHT_UMBER#knockback#LAST# #SLATE#[phys vs phys, knockback]#LAST# the target by %d%s tiles.')
			:format(parameters.distance,
							parameters.distance_scale or '')
	end,
	action = function(self, target, parameters)
		if not parameters.recursive then
			parameters.recursive = function(actor)
				if actor:canBe 'knockback' then
					game.logSeen(target, '%s is struck, they are #LIGHT_UMBER#Knocked Back#LAST# as well!',
											 actor.name:capitalize())
					return true
				end
			end
		end
		if target:canBe 'knockback' then
			game.logSeen(target, '%s is #LIGHT_UMBER#Knocked Back#LAST#!', target.name:capitalize())
			target:knockback(self.x, self.y, parameters.distance, parameters.recursive)
		else
			game.logSeen(target, '%s resists being #LIGHT_UMBER#Knocked Back#LAST#!', target.name:capitalize())
		end
	end,}

newInflict {
	name = 'blind',
	desc = function(parameters)
		return ('try to #YELLOW#Blind#LAST# #SLATE#[phys vs phys, blind]#LAST# the target for %d%s turns. If this fails, instead try to #CCCC00#Partially Blind#LAST# #SLATE#[phys vs phys]#LAST# the target, reducing its accuracy by %d%s #SLATE#[phys, reduced by blind]#LAST#.')
		:format(parameters.duration,
						parameters.duration_scale or '',
						parameters.accuracy,
						parameters.accuracy_scale or '')
	end,
	action = function(self, target, parameters)
		if self:inflictEffect(target, 'BLINDED', parameters.duration, nil, 'blind') then return end
		game.logSeen(target, '%s resists being #YELLOW#Blinded#LAST#!', target.name:capitalize())
		if (target.blind_immune or 0) < 1 then
			self:inflictEffect(target, 'WEIRD_PARTIALLY_BLINDED', parameters.duration, nil ,nil, {
													 accuracy = parameters.accuracy})
		end
	end,}
