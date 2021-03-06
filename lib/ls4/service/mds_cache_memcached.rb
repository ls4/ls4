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


class MemcachedMDSCache < MDSCache
	MDSCacheSelector.register(:mc, self)

	def initialize
		require 'memcache'
	end

	def open(expr)
		@expire = 0
		if m = /\;expire\=(\d+)/.match(expr)
			servers_line = expr[0,m.begin(0)]
			@expire = m[1].to_i
		else
			servers_line = expr
		end
		@servers = servers_line.split(/\s*\,\s*/)
		if @expire == 0
			@expire = 60*60*24
		end
		@mc = MemCache.new(@servers, {:urlencode => false, :compression => false, :multithread => true, :timeout => 1.0})
	end

	def close
		@mc.reset
	end

	def get(key)
		@mc.get(key, true)
	end

	def set(key, val)
		@mc.set(key, val, @expire, true)
	end

	def invalidate(key)
		@mc.delete(key)
	end

	def to_s
		"<MemcachedMDSCache servers=#{@servers.join(',')} expire=#{@expire}>"
	end
end


end
