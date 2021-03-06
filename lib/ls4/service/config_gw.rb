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


class GWConfigService < ConfigService
	def initialize
		@self_location = ""
	end

	attr_accessor :self_location
	attr_accessor :cs_address

	attr_accessor :read_only_version
	attr_accessor :http_gateway_address
	attr_accessor :http_gateway_error_template_file

	ebus_connect :ConfigBus,
		:self_location,
		:read_only_version,
		:http_gateway_address,
		:http_gateway_error_template_file,
		:get_cs_address => :cs_address
end


end
