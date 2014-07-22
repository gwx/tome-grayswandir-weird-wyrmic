module('grayswandir.actor', package.seeall)

local damage_type = require 'engine.DamageType'

--- Apply the temporary values defined in a table.
-- The values will be recorded in source.__tmpvals to be automatically
-- discarded at the appropriate time.
-- @param source The source we're applying the values from/to.
-- @param values The table of {attribute -> increase} values we're applying. Defaults to source.temps.
function _M:autoTemporaryValues(source, values)
	values = values or source.temps
	for attribute, value in pairs(values) do
		self:effectTemporaryValue(source, attribute, value)
	end
end

--- Remove the temporary values defined by autoTemporaryValues, or similar calls.
-- Removes all values in source.__tmpvals.
-- @param source The source we're applying the values of.
function _M:autoTemporaryValuesRemove(source)
	values = values or source.temps
	if not source.__tmpvals then return end
	for _, val in pairs(source.__tmpvals) do
		self:removeTemporaryValue(val[1], val[2])
	end
	source.__tmpvals = nil
end

-- Convenience function for projecting directly.
function _M:projectOn(actor, type, damage)
	if not actor or not actor.x or not actor.y then return end
	return damage_type:get(type).projector(self, actor.x, actor.y, type, damage)
end

-- Add to actor.
require('mod.class.Actor'):importInterface(_M)

return _M
