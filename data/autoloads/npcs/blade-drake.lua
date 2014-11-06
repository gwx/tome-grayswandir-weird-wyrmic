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

if config.settings.tome.grayswandir_weird_wyrmic_weird_drakes == true then

	newEntity{
		define_as = 'BASE_NPC_WEIRD_BLADE_DRAKE',
		type = 'dragon', subtype = 'blade',
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

		innate_drake_talents = true,

		resists = {all = 10,},

		cut_immune = 1,
		knockback_immune = 1,
		stun_immune = 0.5,
		blind_immune = 0.5,}

	newEntity {
		base = 'BASE_NPC_WEIRD_BLADE_DRAKE',
		name = 'weird blade drake hatchling', color = colors.PINK, display = 'd',
		desc = [[A drake hatchling; not too powerful by itself, but it usually comes with its brothers and sisters.]],
		level_range = {11, nil,}, exp_worth = 1,
		rarity = 1,
		max_life = avg(40, 60),
		combat_armor = 5, combat_def = 0,
		combat = {
			dam = levelup(avg(25, 40), 1, 0.6),
			atk = avg(25, 60),
			dammod = {str = 1.1,},},
		on_melee_hit = {BLEED = mbonus(10, 3),},
		make_escort = {
			{type = 'dragon', name = 'weird blade drake hatchling',
			 number = 3, no_subescort = true,},},
		talents {
			T_WEIRD_RENDING_CLAWS = {base = 1, every = 9, max = 7,},
			T_WEIRD_GREAT_SLASH = {base = 1, every = 9, max = 7,},},}

	newEntity {
		base = 'BASE_NPC_WEIRD_BLADE_DRAKE',
		name = 'weird blade drake', color = colors.PINK, display = 'D',
		desc = [[A mature fire drake, armed with deadly breath and nasty claws.]],
		level_range = {19, nil,}, exp_worth = 1,
		rarity = 3,
		max_life = avg(100, 110),
		combat_armor = 12, combat_def = 0,
		combat = {
			dam = levelup(avg(25,70), 1, 1.2),
			atk = avg(25, 70),
			dammod = {str = 1.1,},},
		on_melee_hit = {BLEED = mbonus(41, 9),},
		stats_per_level = 4,
		lite = 1,

		make_escort = {
			{type = 'dragon', name = 'weird blade drake hatchling', number = 1,},},

		resolvers.talents {
			T_WEIRD_RENDING_CLAWS = {base = 2, every = 9, max = 9,},
			T_WEIRD_BELLOWING_ROAR = {base = 1, every = 9, max = 7,},
			T_WEIRD_GREAT_SLASH = {base = 2, every = 7, max = 9,},
			T_WEIRD_TAIL_SWIPE = {base = 1, every = 7, max = 7,},
			T_WEIRD_DRACONIC_CLAW = {base = 2, every = 7, max = 9,},
			T_WEIRD_DRACONIC_AURA = {base = 1, every = 7, max = 9,},},}

	newEntity{
		base = 'BASE_NPC_WEIRD_BLADE_DRAKE',
		name = 'weird blade wyrm', color = colors.SALMON, display = 'D',
		desc = [[An old and powerful blade drake, armed with deadly breath and nasty claws.]],
		resolvers.nice_tile {
			image = 'invis.png',
			add_mos = {{image = 'npc/dragon_blade_weird_blade_wyrm.png', display_h = 2, display_y= - 1,},},},
		level_range = {30, nil,}, exp_worth = 1,
		rarity = 5,
		rank = 3,
		max_life = 190,
		combat_armor = 30, combat_def = 0,
		on_melee_hit = {BLEED = mbonus(70, 20),},
		combat = {
			dam = levelup(avg(25, 110), 1, 2),
			atk = avg(25, 70),
			dammod = {str = 1.1,},},
		stats_per_level = 5,
		lite = 1,
		stun_immune = 0.8,
		blind_immune = 0.8,

		ai = 'tactical',
		ai_tactic = resolvers.tactic 'melee',

		make_escort = {
			{type = 'dragon', name = 'weird blade drake', number = 1,},
			{type = 'dragon', name = 'weird blade drake', number = 1, no_subescort = true},},

		resolvers.talents {
			T_WEIRD_RENDING_CLAWS = {base = 3, every = 5, max = 11,},
			T_WEIRD_BELLOWING_ROAR = {base = 2, every = 5, max = 9,},
			T_WEIRD_WING_BUFFET = {base = 1, every = 5, max = 7,},
			T_WEIRD_GREAT_SLASH = {base = 3, every = 7, max = 11,},
			T_WEIRD_TAIL_SWIPE= {base = 2, every = 7, max = 9,},
			T_WEIRD_RAZOR_BODY = {base = 1, every = 7, max = 7,},
			T_WEIRD_BLADE_ASPECT = {base = 4, every = 7, max = 11,},
			T_WEIRD_BLADE_CLAW = {base = 3, every = 7, max = 9,},
			T_WEIRD_BLADE_AURA = {base = 2, every = 7, max = 9,},
			T_WEIRD_BLADE_BREATH = {base = 1, every = 7, max = 9,},
			T_WEIRD_DRACONIC_CLAW = {base = 3, every = 9, max = 9,},
			T_WEIRD_DRACONIC_AURA = {base = 2, every = 9, max = 9,},
			T_WEIRD_DRACONIC_BREATH = {base = 1, every = 9, max = 9,},},}
end
