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
	game.log('power %s', power or self[power_types[effect.type]](self))
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

function _M:describeInflict(name, parameters)
	return self.inflict_def[name].desc(parameters)
end

-- Add to actor.
require('mod.class.Actor'):importInterface(_M)

return _M
