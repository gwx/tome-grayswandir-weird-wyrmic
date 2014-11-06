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


lib.require 'load-utils'

util.dir_actions.inflicts = 'inflict'
util.load_actions.inflict = function(filename)
	require('mod.class.Actor'):loadInflictDefinition(filename)
	end
util.file_actions['inflicts.lua'] = 'inflict'

superload('mod.class.Actor', function(_M)
		_M.inflict_def = {};

		function _M:newInflict(t)
			assert(t.name, 'no inflict name')
			assert(t.action, 'no inflict action')
			self.inflict_def[t.name] = t
			end

		function _M:loadInflictDefinition(file, env)
			local f, err = util.loadfilemods(file, setmetatable(env or {
						newInflict = function(t) self:newInflict(t) end,
						load = function(f) self:loadInflictDefinition(f, getfenv(2)) end
						}, {__index=_G}))
			if not f and err then error(err) end
			f()
			end

		function _M:inflict(name, target, parameters)
			local inflict = self.inflict_def[name]
			inflict.action(self, target, parameters)
			end

		local power_types = {
			magical = 'combatSpellpower',
			mental = 'combatMindpower',
			physical = 'combatPhysicalpower',}

		local save_types = {
			magical = 'combatSpellResist',
			mental = 'combatMentalResist',
			physical = 'combatPhysicalResist',}

		function _M:inflictEffect(target, name, duration, power, resist, parameters)
			local id = 'EFF_'..name
			local effect = self.tempeffect_def[id]
			if target:checkHit(
				target[save_types[effect.type]](target),
				power or self[power_types[effect.type]](self),
				0, 95)
			then return end

			if resist then
				if type(resist) == 'string' and not target:canBe(resist) then return end
				if type(resist) == 'number' and rng.percent(resist) then return end
				end

			if not parameters then parameters = {} end
			target:setEffect(id, duration, parameters)
			return true
			end

		function _M:describeInflict(name, tense, parameters)
			return self.inflict_def[name].desc(parameters, tense)
			end
		end)
