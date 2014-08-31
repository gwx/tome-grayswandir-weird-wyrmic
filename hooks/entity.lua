local hook = function(self, data, force)
  local load_npc = function(name)
    local file = '/data-grayswandir-weird-wyrmic/npcs/'..name..'.lua'
    if data.loaded[file] and not force then return end
    self:loadList(file, data.no_default, data.res, data.mod, data.loaded)
  end

	-- Each specific elemental drake file..
	for _, e in pairs {'fire', 'cold', 'multihued', 'storm', 'venom', 'wild', } do
		if data.file == '/data/general/npcs/'..e..'-drake.lua' then
			load_npc(e..'-drake')
		end
	end

	-- Sand Drakes are in the sandworm file.
	if data.file == '/data/general/npcs/sandworm.lua' then
		load_npc 'sand-drake'
	end

	-- Add blade/stone drakes to the all file.
	if data.file == '/data/general/npcs/all.lua' then
		for _, e in pairs {'blade', 'stone',} do
			load_npc(e..'-drake')
		end
	end
end
class:bindHook('Entity:loadList', hook)
