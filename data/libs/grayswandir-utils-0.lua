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

-- Various utility functions.
if not table.get(grayswandir, 'utils') then table.set(_G, 'grayswandir', 'utils', {}) end

local g = grayswandir.utils

--[=[
  If the source contains the given key.
  returns the key, the value, and if it succeeded.
]=]
function g.hask(source, key)
  for k, v in pairs(source) do
    if k == key then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  If the source contains the given value.
  returns the key, the value, and if it succeeded.
]=]
function g.hasv(source, value)
  for k, v in pairs(source) do
    if v == value then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  Return the result of mapping f across the values of source.
]=]
function g.mapv(source, f)
  local result = {}
  for k, v in pairs(source) do
    result[k] = f(v)
  end
  return result
end

--[=[
  Increment the given value by 1, creating it if it doesn't exist.
]=]
function g.inc(table, key, amount)
  table[key] = (table[key] or 0) + (amount or 1)
  if table[key] <= 0 then table[key] = nil end
end

--[=[
  Decrement the given value by 1, setting to nil if it reaches 0.
]=]
function g.dec(table, key, amount)
  g.inc(table, key, -(amount or 1))
end

--[=[
  Changes a table so that # counts all the entries.
]=]
function g.countable(table)
  local meta = getmetatable(table)
  if not meta then
    meta = {}
    setmetatable(table, meta)
  end

  if meta.countable_size then return end

  local size = 0
  for k, v in pairs(table) do
    size = size + 1
  end
  meta.countable_size = size

  local newindex = meta.__newindex
  if newindex then
    meta.__newindex = function(table, key, value)
      local was = table[key]
      newindex(table, key, value)
      local is = table[key]
      if was and is == nil then
        meta.countable_size = meta.countable_size - 1
      elseif was == nil and is then
        meta.countable_size = meta.countable_size + 1
      end
    end
  else
    meta.__newindex = function(table, key, value)
      local was = table[key]
      rawset(table, key, value)
      local is = rawget[key]
      if was and is == nil then
        meta.countable_size = meta.countable_size - 1
      elseif was == nil and is then
        meta.countable_size = meta.countable_size + 1
      end
    end
  end

  meta.__len = function(table) return meta.countable_size end
end
