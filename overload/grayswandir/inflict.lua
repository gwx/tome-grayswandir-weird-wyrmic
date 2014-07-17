module('grayswandir.inflict', package.seeall)

_M.inflict_def = {};

function _M:newInflict(t)
	assert(t.name, 'no inflict name')
	assert(t.action, 'no inflict action')
	self.inflict_def[t.name] = t
end

function _M:loadDefinition(file, env)
	local f, err = util.loadfilemods(file, setmetatable(env or {
		newInflict = function(t) self:newInflict(t) end,
		load = function(f) self:loadDefinition(f, getfenv(2)) end
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
		target[save_types[effect.type]],
		power or self[power_types[effect.type]],
		0, 95)
		and
		(resist and
			 (type(resist) == 'string' and
					target:canBe(resist) or
					rng.percent(resist)))
	then
		if not parameters then parameters = {} end
		target:setEffect(id, duration, parameters)
		return true
	end
end

function _M:describeInflict(name, parameters)
	return self.inflict_def[name](paremeters)
end

-- Add to actor.
require('mod.class.Actor'):importInterface(_M)

return _M
