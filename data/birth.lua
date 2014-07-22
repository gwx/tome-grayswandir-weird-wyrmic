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


local wilders = getBirthDescriptor('class', 'Wilder').descriptor_choices.subclass
wilders['Weird Wyrmic'] = wilders.Wyrmic

newBirthDescriptor {
	type = 'subclass',
	name = 'Weird Wyrmic',
	locked = function() return profile.mod.allow_build.wilder_wyrmic or 'hide' end,
	desc = {
		'My own take on wyrmics:',
		'Wyrmics are fighters who have learnt how to mimic some of the aspects of the dragons.',
		'They have access to talents normally belonging to the various kind of drakes.',
		'Their most important stats are: Strength and Willpower',
		'#GOLD#Stat modifiers:',
		'#LIGHT_BLUE# * +4 Strength, +0 Dexterity, +1 Constitution',
		'#LIGHT_BLUE# * +0 Magic, +4 Willpower, +0 Cunning',
		'#GOLD#Life per level:#LIGHT_BLUE# +2',},
	power_source = {nature = true, technique = true,},
	stats = { str=4, wil=4, con=1, },
	talents_types = {
		['wild-gift/draconic-form'] = {true, 0.3,},
		['wild-gift/draconic-might'] = {true, 0.3,},
		['wild-gift/fire-aspect'] = {true, 0.3,},
		['wild-gift/ice-aspect'] = {true, 0.3,},
		['wild-gift/storm-aspect'] = {true, 0.3,},
		['wild-gift/sand-aspect'] = {true, 0.3,},
		['wild-gift/higher-draconic']={false, 0.3},
		['wild-gift/call'] = {true, 0.2,},
		['wild-gift/harmony'] = {false, 0.1,},
		['wild-gift/fungus']={true, 0.1},
		['cunning/survival']={false, 0},
		['technique/shield-offense']={true, 0.1},
		['technique/2hweapon-assault']={true, 0.1},
		['technique/combat-techniques-active']={false, 0},
		['technique/combat-techniques-passive']={true, 0},
		['technique/combat-training']={true, 0},},
	talents = {
		T_WEIRD_RAGING_RUSH = 1,
		T_WEIRD_FLASHFREEZE = 1,
		T_MEDITATION = 1,
		T_WEAPONS_MASTERY = 1,
		T_WEAPON_COMBAT = 1,},
	copy = {
		drake_touched = 2,
		max_life = 110,
		resolvers.equipbirth {
			id = true,
			{type='weapon', subtype='battleaxe', name='iron battleaxe', autoreq=true, ego_chance=-1000},
			{type='armor', subtype='light', name='rough leather armour', autoreq=true, ego_chance=-1000},},
		resolvers.inventory {
			id = true, inven = 'QS_MAINHAND',
			{type = 'weapon', subtype = 'mace', name = 'iron mace',
			 autoreq = true, ego_chance = -1000,},},
		resolvers.inventorybirth {
			id = true,
			{type = 'armor', subtype = 'shield', name = 'iron shield',
			 autoreq = true, ego_chance = -1000,},},},
	copy_add = {
		life_rating = 2,},}
