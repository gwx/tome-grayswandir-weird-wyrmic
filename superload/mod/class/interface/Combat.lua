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


local _M = loadPrevious(...)

-- Generic Scaling Function
-- Examples:
--
-- self:wwScale {min = 10, max = 50, stat = 'str',}
-- Returns 10 at 10 str, 50 at 100 str, and 77 at 200 str.
--
-- self:wwScale {max = 50, limit = 100, stat = 'str',}
-- Returns 16.67 at 10 str, 50 at 100 str, and 65.4 at 200 str.
--
-- self:wwScale {min = 1.2, max = 1.9, talent = t,}
-- Returns 1.2 at talent level 1 and 1.9 at talent level 5
--
-- self:wwScale {min = 3, max = 7, talent = t, stat = 'cun', round = 'floor',}
-- At talent level 1, cunning 10:   3.00
-- At talent level 5, cunning 10:   5.55 (floored to 5.00)
-- At talent level 5, cunning 100:  7.00
function _M:wwScale(t)
	local value = 5
	if t.talent then value = value * 0.2 * self:getTalentLevel(t.talent) end

	if t.mult then value = (value - 1) * t.mult + 1 end

	if t.stat then
		-- For both a talent and stat, the stat = 0 is at 50% power.
		if t.talent then
			value = ((value - 1) * (self:getStat(t.stat) + 100) * 0.005) + 1
		-- For scaling only on a stat, the stat = 10 is at 0% power.
		else
			value = ((value - 1) * (self:getStat(t.stat) - 10) / 90) + 1
		end
	end

	local power
	if t.power == 'attack' then power = self:combatAttack()
	elseif t.power == 'physical' then power = self:combatPhysicalpower()
	elseif t.power == 'mind' then power = self:combatMindpower()
	elseif t.power == 'spell' then power = self:combatSpellpower()
	end
	if power then
		-- For both a talent and power, the power = 0 is at 50% power.
		if t.talent then
			value = ((value - 1) * (power + 100) * 0.005) + 1
		-- For scaling only on a power, the power = 0 is at 0% power.
		else
			value = ((value - 1) * power * 0.01) + 1
		end
	end

	if t.limit then
		value = self:combatTalentLimit(value, t.limit, t.min, t.max)
	else
		value = self:combatTalentScale(value, t.min, t.max)
	end

	if t.round == 'floor' then value = math.floor(value)
	elseif t.round == 'ceil' then value = math.ceil(value)
	end

	if t.scale == 'damage' then value = self:rescaleDamage(value) end

	return value
end

-- Phase this one in over time:

-- Generic Scaling Function
--
-- Takes a table with the following arguments. Any or all may be missing.
--
-- low: The value to return when at an effective score of 0.
-- high: The value to return when at an effective score of 100.
-- limit: If present, influences the value returned when effective score is
--   over 100. The result will get close to but never reach this value.
-- synergy: How much the different inputs affect each other. At 0, the
--   different components will just be added together for the final score.
--   At 1, they will be multiplied, so if any input is 0 the low value will
--   be the result. Defaults to 0.5.
-- curve: How to curve the result. Result will be raised to this power, making
--   the initial points worth more or less than the later ones.
--   Defaults to 0.75.
-- after: An effect to apply after the result is computed:
--   floor: Round down to the nearest integer.
--   ceil: Round up to the nearest integer.
--   damage: Apply the general scaling for damage values.
--
-- Actual power inputs are on the numbered indices. They are expected to be a
-- value from 0 to 100. There are also several shortcuts:
--
-- talent id or table: Scale from 0% at talent level 1 to 100% at
--   talent level 5.
-- 3 letter stat id, eg. 'str': Scale with the stat value.
-- 'atk': Scale with accuracy.
-- 'phys': Scale with physical power.
-- 'mind': Scale with mind power.
-- 'spell': Scale with spell power.
function _M:scale(t)
	if #t == 0 then return t.high or 1 end

	local synergy_score = 100
	local asynergy_score = 0

	for _, x in ipairs(t) do
		local score = 1

		if type(x) == 'table' then x = x.id end

 		if x:sub(1, 2) == 'T_' then score = (self:getTalentLevel(x) - 1) * 25
		elseif x == 'str' then score = self:getStr()
		elseif x == 'dex' then score = self:getDex()
		elseif x == 'con' then score = self:getCon()
		elseif x == 'mag' then score = self:getMag()
		elseif x == 'wil' then score = self:getWil()
		elseif x == 'cun' then score = self:getCun()
		elseif x == 'atk' then score = self:combatAttack()
		elseif x == 'phys' then score = self:combatPhysicalpower()
		elseif x == 'mind' then score = self:combatMindpower()
		elseif x == 'spell' then score = self:combatSpellpower()
		end

		synergy_score = synergy_score * math.max(0, score) * 0.01
		asynergy_score = asynergy_score + score
	end
	asynergy_score = asynergy_score / #t

	local synergy = t.synergy or 0.5
	local score = synergy_score * synergy + asynergy_score * (1 - synergy)

	local result
	local low = t.low or 0
	local high = t.high or (t.limit and (t.limit - low) * 0.5 + low) or t.low + 1
	local curve = t.curve or 0.75
	if score <= 100 or not t.limit then
		local diff = high - low
		result = low + diff * (score * 0.01) ^ curve
	else
		local diff = t.limit - high
		curve = (t.limit_curve or curve) * 100
		score = score - 100
		result = high + diff * score / (score + curve)
	end

	if t.after == 'floor' then result = math.floor(result)
	elseif t.after == 'ceil' then result = math.ceil(result)
	elseif t.after == 'damage' then result = self:rescaleDamage(result)
	end

	return result
end

return _M
