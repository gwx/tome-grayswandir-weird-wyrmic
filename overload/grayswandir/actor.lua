module('grayswandir.actor', package.seeall)

local damage_type = require 'engine.DamageType'

-- Convenience function for projecting directly.
function _M:projectOn(actor, type, damage)
	if not actor or not actor.x or not actor.y then return end
	return damage_type:get(type).projector(self, actor.x, actor.y, type, damage)
end

-- List all temporary effects satisfying a filter.
function _M:filterTemporaryEffects(filter)
	local effects = {}
	for id, parameters in pairs(self.tmp) do
		local effect = self.tempeffect_def[id]
		if filter(effect, parameters) then table.insert(effects, id) end
	end
	return effects
end

-- Add to actor.
require('mod.class.Actor'):importInterface(_M)

return _M
