module('grayswandir', package.seeall)

--[=[
  Decends recursively through a table by the given list of keys.

  1st return: The first non-table value found, or the final value if
  we ran out of keys.

  2nd return: If the list of keys was exhausted

  Meant to replace multiple ands to get a value:
  "a and a.b and a.b.c" turns to "rget(a, 'b', 'c')"
]=]
function _M.get(table, ...)
  if type(table) ~= 'table' then return table, false end
  for _, key in ipairs({...}) do
    if type(table) ~= 'table' then return table, false end
    table = table[key]
  end
  return table, true
end

--[=[
  Set the nested value in a table, creating empty tables as needed.
]=]
function _M.set(table, ...)
  if type(table) ~= 'table' then return false end
  local args = {...}
  for i = 1, #args - 2 do
    local key = args[i]
    local subtable = table[key]
    if not subtable then
      subtable = {}
      table[key] = subtable
    end
    table = subtable
  end
  table[args[#args - 1]] = args[#args]
end

--[=[
  Find the first pair which for which f(key, value) returns true.
  returns the key, the value, and if it succeeded.
]=]
function _M.find(source, f)
  for k, v in pairs(source) do
    if f(k, v) then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  Find the first pair which for which f(value) returns true.
  returns the key, the value, and if it succeeded.
]=]
function _M.findv(source, f)
  for k, v in pairs(source) do
    if f(v) then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  If the source contains the given key.
  returns the key, the value, and if it succeeded.
]=]
function _M.hask(source, key)
  for k, v in pairs(source) do
    if k == key then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  If the source contains the given value.
  returns the key, the value, and if it succeeded.
]=]
function _M.hasv(source, value)
  for k, v in pairs(source) do
    if v == value then return k, v, true end
  end
  return nil, nil, false
end

--[=[
  Return the result of mapping f across the values of source.
]=]
function _M.mapv(source, f)
  local result = {}
  for k, v in pairs(source) do
    result[k] = f(v)
  end
  return result
end

--[=[
  Increment the given value by 1, creating it if it doesn't exist.
]=]
function _M.inc(table, key, amount)
  table[key] = (table[key] or 0) + (amount or 1)
  if table[key] <= 0 then table[key] = nil end
end

--[=[
  Decrement the given value by 1, setting to nil if it reaches 0.
]=]
function _M.dec(table, key, amount)
  _M.inc(table, key, -(amount or 1))
end

--[=[
  Changes a table so that # counts all the entries.
]=]
function _M.countable(table)
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

return _M
