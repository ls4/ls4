#
#  SpreadOSD
#  Copyright (C) 2010  FURUHASHI Sadayuki
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
require 'tokyocabinet'

module SpreadOSD


class LogStorageIndex
	def initialize
		@db = TokyoCabinet::HDB.new
	end

	def open(path)
		success = @db.open(path, TokyoCabinet::HDB::OWRITER|TokyoCabinet::HDB::OCREAT)
		unless success
			raise "can't open database #{path}: #{@db.errmsg(@db.ecode)}"
		end
	end

	def close
		@db.close
	end

	def set(oid, logid, lskey)
		val = [logid].pack('N') + lskey.dump
		key = [oid>>32, oid&0xffffffff].pack('NN')
		success = @db.put(key, val)
		unless success
			raise "failed to put key #{@db.errmsg(@db.ecode)}"
		end
		nil
	end

	def get(oid)
		key = [oid>>32, oid&0xffffffff].pack('NN')
		val = @db.get(key)
		unless val
			return nil, nil
		end
		logid = val.slice!(0,4).unpack('N')[0]
		lskey = LogStorage::Key.load(val)
		return logid, lskey
	end
end


end
