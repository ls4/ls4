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


class DSConfigService < GWConfigService
	def run
		@self_node = Node.new(@self_nid, @self_address, @self_name, @self_rsids, @self_location)
	end

	attr_accessor :self_nid
	attr_accessor :self_name
	attr_accessor :self_address
	attr_accessor :self_rsids
	attr_accessor :storage_path
	attr_accessor :ulog_path
	attr_accessor :rts_path

	attr_accessor :http_redirect_port
	attr_accessor :http_redirect_path_format

	attr_reader :self_node

	ebus_connect :ConfigBus,
		:self_nid,
		:self_name,
		:self_address,
		:self_rsids,
		:self_node,
		:http_redirect_port,
		:http_redirect_path_format,
		:get_storage_path    => :storage_path,
		:get_ulog_path       => :ulog_path,
		:get_rts_path        => :rts_path

	ebus_connect :ProcessBus,
		:run
end


end
