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

local avg = resolvers.rngavg
local talents = resolvers.talents
local mbonus = resolvers.mbonus
local levelup = resolvers.levelup

if config.settings.tome.grayswandir_weird_wyrmic_original_drakes == false then
	for i = #loading_list, 1, -1 do
		local e = loading_list[i]
		if e.type == 'dragon' and e.subtype == 'cold' then
			table.remove(loading_list, i)
		end
	end
end

if config.settings.tome.grayswandir_weird_wyrmic_weird_drakes == true then

	newEntity{
		define_as = 'BASE_NPC_WEIRD_ICE_DRAKE',
		type = 'dragon', subtype = 'ice',
		display = 'D', color=colors.WHITE,

		body = {INVEN = 10, MAINHAND = 1, OFFHAND = 1, BODY = 1,},
		resolvers.drops {chance = 100, nb = 1, {type = 'money',},},

		infravision = 10,
		life_rating = 15,
		rank = 2,
		size_category = 5,

		autolevel = 'drake',
		ai = 'dumb_talented_simple',
		ai_state = {ai_move = 'move_complex', talent_in = 2,},
		stats = {str = 20, dex = 20, mag = 30, con = 16,},

		resists = {COLD = 100,},

		knockback_immune = 1,
		stun_immune = 0.5,
		blind_immune = 0.5,}

	newEntity {
		base = 'BASE_NPC_WEIRD_ICE_DRAKE',
		name = 'weird ice drake hatchling', color = colors.RED, display = 'd',
		image = 'npc/dragon_cold_cold_drake_hatchling.png',
		desc = [[A drake hatchling; not too powerful by itself, but it usually comes with its brothers and sisters.]],
		level_range = {8, nil,}, exp_worth = 1,
		rarity = 1,
		max_life = avg(40, 60),
		combat_armor = 5, combat_def = 0,
		combat = {
			dam = levelup(avg(25, 40), 1, 0.6),
			atk = avg(25, 60),
			--apr = 25,
			dammod = {str = 1.1,},
			sound = {'creatures/cold_drake/attack%d', 1, 2, vol = 0.4,},},
		--on_melee_hit = {COLD = mbonus(7, 2),},
		on_melee_hit = {COLD = mbonus(4, 1),},
		sound_moam = {'creatures/cold_drake/on_hit%d', 1, 2, vol = 0.4,},
		sound_die = {'creatures/cold_drake/death%d', 1, 1, vol = 0.4,},
		make_escort = {
			{type = 'dragon', subtype = 'ice', name = 'weird ice drake hatchling',
			 number = 3, no_subescort = true,},},
		talents {
			T_WEIRD_RENDING_CLAWS = {base = 1, every = 9, max = 7,},
			T_WEIRD_FLASHFREEZE = {base = 1, every = 9, max = 7,},},}

	newEntity {
		base = 'BASE_NPC_WEIRD_ICE_DRAKE',
		name = 'weird ice drake', color = colors.SLATE, display = 'D',
		image = 'npc/dragon_cold_cold_drake.png',
		desc = [[A mature cold drake, armed with deadly breath and nasty claws.]],
		level_range = {14, nil,}, exp_worth = 1,
		rarity = 3,
		max_life = avg(100, 110),
		combat_armor = 12, combat_def = 0,
		combat = {
			dam = levelup(avg(25,70), 1, 1.2),
			atk = avg(25, 70),
			apr = 25,
			dammod = {str = 1.1,},
			sound = {'creatures/cold_drake/attack%d', 1, 2, vol = 1,},},
		on_melee_hit = {COLD = mbonus(15, 10)},
		stats_per_level = 4,
		lite = 1,
		sound_moam = {'creatures/cold_drake/on_hit%d', 1, 2, vol = 1,},
		sound_die = {'creatures/cold_drake/death%d', 1, 1, vol = 1,},

		make_escort = {
			{type = 'dragon', name = 'weird ice drake hatchling', number = 1,},},

		resolvers.talents {
			T_WEIRD_RENDING_CLAWS = {base = 2, every = 5, max = 9,},
			T_WEIRD_BELLOWING_ROAR = {base = 1, every = 5, max = 7,},
			T_WEIRD_FLASHFREEZE = {base = 2, every = 7, max = 9,},
			T_WEIRD_SHATTERING_SMASH = {base = 1, every = 7, max = 7,},
			T_WEIRD_ICE_CLAW = {base = 2, every = 7, max = 9,},
			T_WEIRD_ICE_AURA = {base = 1, every = 7, max = 9,},
			T_WEIRD_DRACONIC_CLAW = {base = 2, every = 7, max = 9,},
			T_WEIRD_DRACONIC_AURA = {base = 1, every = 7, max = 9,},},}

	newEntity{
		base = 'BASE_NPC_WEIRD_ICE_DRAKE',
		name = 'weird ice wyrm', color = colors.AQUAMARINE, display = 'D',
		desc = [[An old and powerful ice drake, armed with deadly breath and nasty claws.]],
		resolvers.nice_tile {
			image = 'invis.png',
			add_mos = {{image = 'npc/dragon_cold_ice_wyrm.png', display_h = 2, display_y= - 1,},},},
		level_range = {25, nil,}, exp_worth = 1,
		rarity = 5,
		rank = 3,
		max_life = 190,
		combat_armor = 30, combat_def = 0,
		on_melee_hit = {COLD = mbonus(25, 10),},
		combat = {
			dam = levelup(avg(25, 110), 1, 2),
			atk = avg(25, 70),
			apr = 25,
			dammod = {str = 1.1,},
			sound = {'creatures/cold_drake/attack%d', 1, 2, vol = 1.4,},},
		stats_per_level = 5,
		lite = 1,
		stun_immune = 0.8,
		blind_immune = 0.8,

		ai = 'tactical',
		ai_tactic = resolvers.tactic 'melee',

		sound_moam = {'creatures/cold_drake/on_hit%d', 1, 2, vol = 1.4,},
		sound_die = {'creatures/cold_drake/death%d', 1, 1, vol = 1.4,},

		make_escort = {
			{type = 'dragon', name = 'weird ice drake', number = 1,},
			{type = 'dragon', name = 'weird ice drake', number = 1, no_subescort = true},},

		resolvers.talents {
			T_WEIRD_RENDING_CLAWS = {base = 3, every = 5, max = 11,},
			T_WEIRD_BELLOWING_ROAR = {base = 2, every = 5, max = 9,},
			T_WEIRD_WING_BUFFET = {base = 1, every = 5, max = 7,},
			T_WEIRD_FLASHFREEZE = {base = 3, every = 7, max = 11,},
			T_WEIRD_SHATTERING_SMASH = {base = 2, every = 7, max = 9,},
			T_WEIRD_RIGID_BODY = {base = 1, every = 7, max = 7,},
			T_WEIRD_ICE_ASPECT = {base = 4, every = 7, max = 11,},
			T_WEIRD_ICE_CLAW = {base = 3, every = 7, max = 9,},
			T_WEIRD_ICE_AURA = {base = 2, every = 7, max = 9,},
			T_WEIRD_ICE_BREATH = {base = 1, every = 7, max = 9,},
			T_WEIRD_DRACONIC_CLAW = {base = 3, every = 9, max = 9,},
			T_WEIRD_DRACONIC_AURA = {base = 2, every = 9, max = 9,},
			T_WEIRD_DRACONIC_BREATH = {base = 1, every = 9, max = 9,},},

		ingredient_on_death = 'ICE_WYRM_TOOTH',}

end
