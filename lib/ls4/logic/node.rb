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


Address = MessagePack::RPC::Address

class Node
	def initialize(nid=0, address=nil, name=nil, rsids=[], location=nil)
		@nid = nid
		@address = address
		@name = name
		@rsids = rsids
		@location = location
	end

	attr_reader :nid
	attr_accessor :address
	attr_accessor :name
	attr_accessor :rsids
	attr_accessor :location

	def session
		$net.get_session(*@address)
	end

	def to_s
		"Node<#{@nid} #{@address} #{@name.dump} #{@rsids.inspect} #{@location.inspect}>"
	end

	def ==(o)
		# FIXME
		@nid == o.nid && @address == o.address
	end

	public
	def to_msgpack(out = '')
		[@nid, @address.dump, @name, @rsids, @location].to_msgpack(out)
	end
	def from_msgpack(obj)
		@nid = obj[0]
		@address = Address.load(obj[1])
		@name = obj[2]
		@rsids = obj[3]
		@location = obj[4]
		self
	end
end


end
