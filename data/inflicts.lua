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
	name = 'blind',
	desc = function(parameters)
		return ('try to #YELLOW#blind#LAST# #SLATE#[phys vs phys, blind]#LAST# the target for %d turns. If this fails, instead try to #GREY#partially blind#LAST# #SLATE#[phys vs phys]#LAST# the target, reducing its accuracy by %d #SLATE#[phys, reduced by blind]#LAST#.')
		:format(parameters.duration,
						parameters.accuracy)
	end,
	action = function(self, target, parameters)
		if self:inflictEffect(target, 'BLIND', parameters.duration, nil, 'blind') then return end
		self:inflictEffect(target, 'WEIRD_PARTIALLY_BLINDED', parameters.duration, nil ,nil, {
												 accuracy = parameters.accuracy})
	end,}
