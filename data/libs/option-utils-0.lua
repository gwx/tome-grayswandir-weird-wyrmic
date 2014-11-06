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

if not table.get(_G, 'grayswandir', 'class') then
	table.set(_G, 'grayswandir', 'class', {}) end

local OM = {}
grayswandir.class.OptionMaker = class.make(OM)

function OM:init(t)
	table.merge(self, t)
	assert(self.options, 'No options object.')
	self.id_prefix = self.id_prefix or ''
	self.name_prefix = self.name_prefix or ''
	end

function OM:boolean(short_id, display_name, default, description, action, on_value, off_value)
	local id = self.id_prefix .. short_id
	on_value = on_value or 'enabled'
	off_value = off_value or 'disabled'
	-- Set the default value.
	if config.settings.tome[id] == nil then config.settings.tome[id] = default end
	-- Create the option.
	local Textzone = require 'engine.ui.Textzone'
	table.insert(self.options.list, {
			name = string.toTString(('#GOLD##{bold}#%s%s#WHITE##{normal}#')
					:format(self.name_prefix, display_name)),
			zone = Textzone.new {
				width = self.options.c_desc.w,
				height = self.options.c_desc.h,
				text = string.toTString(description),},
			status = function(item)
				return tostring(config.settings.tome[id] and on_value or off_value)
				end,
			fct = function(item)
				config.settings.tome[id] = not config.settings.tome[id]
				local name = 'tome.'..id
				game:saveSettings(name, ('%s = %s\n'):format(name, tostring(config.settings.tome[id])))
				self.options.c_list:drawItem(item)
				if action then action(config.settings.tome[id]) end
				end,})
	end

-- Add in to autoload.
lib.require 'load-utils'
util.dir_actions.options = 'option'
util.load_actions.option = function(fullname, filename)
	local f, err = loadfile(fullname)
	if err then error(err) end
	local kind = filename:sub(0, -5)
	class:bindHook('GameOptions:generateList', function(options, data)
			if data.kind ~= kind then return end
			-- not confusing at all.
			setfenv(f, setmetatable({
						options = options,
						data = data,},
					{__index = _G,}))
			f()
			setfenv(f, {})
			end)
	end
