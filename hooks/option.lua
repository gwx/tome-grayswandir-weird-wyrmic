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


local hook = function(self, data)
  if data.kind == 'gameplay' then
    local textzone = require 'engine.ui.Textzone'
    local tome = config.settings.tome
    self.list = self.list or {}

    -- Option Creation function.
    local add_boolean_option = function(short_id, display_name, default, description, action)
      local id = 'grayswandir_weird_wyrmic_'..short_id
      -- Set default value.
      if tome[id] == nil then tome[id] = default end
      -- Create new option.
      local option = {
          name = string.toTString(
            ('#GOLD##{bold}#Weird Wyrmic: %s#WHITE##{normal}#')
              :format(display_name)),
          zone = textzone.new {
            width = self.c_desc.w,
            height = self.c_desc.h,
            text = string.toTString(description),},
          status = function(item)
            return tostring(tome[id] and 'enabled' or 'disabled')
          end,
          fct = function(item)
            tome[id] = not tome[id]
            local name = 'tome.'..id
            game:saveSettings(
              name, ('%s = %s\n'):format(name, tostring(tome[id])))
            self.c_list:drawItem(item)
						if action then action(tome[id]) end
          end,}
      table.insert(self.list, option)
    end

    add_boolean_option(
      'original_drakes',
      'Original Drakes',
			false,
      'This allows the original drake enemies to be generated.')

    add_boolean_option(
      'weird_drakes',
      'Weird Drakes',
			true,
      'This allows weird drake enemies to be generated.')

  end
end
class:bindHook('GameOptions:generateList', hook)
