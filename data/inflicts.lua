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
		return ('try to #YELLOW#blind#LAST# #SLATE#[phys vs phys, blind]#LAST# the target for %d%s turns. If this fails, instead try to #GREY#partially blind#LAST# #SLATE#[phys vs phys]#LAST# the target, reducing its accuracy by %d%s #SLATE#[phys, reduced by blind]#LAST#.')
		:format(parameters.duration,
						parameters.duration_scale or '',
						parameters.accuracy,
						parameters.accuracy_scale or '')
	end,
	action = function(self, target, parameters)
		if self:inflictEffect(target, 'BLINDED', parameters.duration, nil, 'blind') then return end
		game.logSeen(target, '%s resists being #YELLOW#blinded#LAST#!', target.name:capitalize())
		self:inflictEffect(target, 'WEIRD_PARTIALLY_BLINDED', parameters.duration, nil ,nil, {
												 accuracy = parameters.accuracy})
	end,}
