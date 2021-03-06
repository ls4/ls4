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


class RelayTimeStampBus < Bus
	call_slot :init

	call_slot :open
end


module RelayTimeStamp
	#def close
	#end

	#def get
	#end

	#def set(pos, &block)
	#end
end


class RelayTimeStampSelector
	IMPLS = {}

	def self.register(name, klass)
		IMPLS[name.to_sym] = klass
		nil
	end

	def self.select_class(uri)
		uri ||= "mem:"

		if m = /^(\w{1,8})\:(.*)/.match(uri)
			type = m[1].to_sym
			expr = m[2]
		else
			type = :file
			expr = uri
		end

		klass = IMPLS[type]

		unless klass
			"unknown RelayTimeStamp type: #{type}"
		end

		return klass, expr
	end

	def self.select!(uri)
		klass, expr = select_class(uri)
		klass.init

		RelayTimeStampBus.init(expr)
	end

	def self.open!
		select!(ConfigBus.get_rts_path)
	end
end


class RelayTimeStampService < Service
	#def init(expr)
	#end

	#def open(nid)
	#end

	ebus_connect :RelayTimeStampBus,
		:open,
		:init
end


end
