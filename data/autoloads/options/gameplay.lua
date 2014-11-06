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

local om = grayswandir.class.OptionMaker.new {
	options = options,
	id_prefix = 'grayswandir_weird_wyrmic_',
	name_prefix = 'Weird Wyrmic: ',}

om:boolean(
	'original_drakes',
	'Original Drakes',
	false,
	'This allows the original drake enemies to be generated.')

om:boolean(
	'weird_drakes',
	'Weird Drakes',
	true,
	'This allows weird drake enemies to be generated.')
