#
#  LS4
#  Copyright (C) 2010-2011  FURUHASHI Sadayuki
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module LS4


class CSConfigService < ConfigService
	#attr_accessor :self_address

	attr_accessor :mds_uri
	attr_accessor :mds_cache_uri

	ebus_connect :ConfigBus,
		:get_initial_mds_uri => :mds_uri,
		:get_initial_mds_cache_uri => :mds_cache_uri
end


end
