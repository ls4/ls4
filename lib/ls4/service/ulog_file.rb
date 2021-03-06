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


class FileUpdateLog < UpdateLogService
	UpdateLogSelector.register(:file, self)

	# File format:
	# +-------+-------+-------+----...+---
	# |   8   |   8   |   8   |  48    | records...
	# +-------+-------+-------+----...+---
	# magic "SoULog00"
	#         start-timestamp
	#                 pos
	#                         reserved...
	#
	# Record format:
	# +------+-------+------...+
	# |vbcode|msgpack|  raw    |
	# +------+-------+------...+
	# record-size
	#        metadata
	#                data
	#        |                 |
	#        |-----------------|
	#            record-size
	#

	HEADER_SIZE = 64
	MAGICK = "SoULog00"

	class Record
		def initialize(reltime, data)
			@reltime = reltime
			@data = data
		end

		attr_reader :reltime
		attr_reader :data

		def write(stream)
			meta = [@reltime]

			bmeta = meta.to_msgpack
			rsize = bmeta.size + @data.size
			brsize = VariableByteCode.encode(rsize)

			stream.write(brsize)
			stream.write(bmeta)
			stream.write(@data)

			brsize.size + bmeta.size + @data.size
		end

		def self.read(stream)
			new *read_impl(stream, true)
		end

		def self.read_nodata(stream)
			return read_impl(stream, false)
		end

		private
		def self.read_impl(stream, need_data)
			ipos = stream.pos

			hdr = stream.read(32)
			if hdr.nil? || hdr.empty?
				return nil
			end

			rsize, rsize_len = VariableByteCode.decode_index(hdr)

			u = MessagePack::Unpacker.new
			meta_len = u.execute(hdr, rsize_len) - rsize_len
			unless u.finished?
				return nil  # FIXME
			end
			meta = u.data

			reltime = meta[0]

			if need_data
				stream.pos = ipos + rsize_len + meta_len
				data = stream.read(rsize - meta_len)
				return reltime, data
			else
				stream.pos = ipos + rsize_len + rsize
				return reltime
			end
		end
	end

	class RecordRef
		def initialize(reltime, pos)
			@reltime = reltime
			@pos = pos
		end

		attr_reader :reltime
		attr_reader :pos

		def <=>(o)
			@reltime <=> o.reltime
		end

		def read_body(stream)
			stream.pos = @pos
			Record.read(stream)
		end

		def self.read(stream)
			pos = stream.pos
			reltime = Record.read_nodata(stream)
			new(reltime, pos)
		end
	end

	class Header
		def initialize(atime, pos)
			@atime = atime
			@pos = pos
		end

		attr_reader :atime
		attr_reader :pos

		def dump
			raw = ""
			raw << MAGICK
			raw << [ atime>>32,  atime&0xffffffff].pack('NN')
			raw << [pos>>32, pos&0xffffffff].pack('NN')
			raw << ([0] * (HEADER_SIZE - raw.size)).pack('C*')
			raw
		end

		def self.load(raw)
			magick = raw[0,8]
			if magick != MAGICK
				raise "magick not match"
			end

			atime = raw[8,8].unpack('NN')
			atime = (atime[0]<<32) | atime[1]
			pos = raw[16,8].unpack('NN')
			pos = (pos[0]<<32) | pos[1]

			new(atime, pos)
		end

		def self.read_offset(stream)
			stream.pos = 16
			raw = stream.read(8)
			pos = raw.unpack('NN')
			pos = (pos[0]<<32) | pos[1]
			pos
		end

		def self.write_offset(stream, pos)
			stream.pos = 16
			raw = [pos>>32, pos&0xffffffff].pack('NN')
			stream.write(raw)
			stream
		end
	end

	class LogFile
		def initialize(path, atime)
			@path = path
			@file = File.open(@path, File::RDWR|File::CREAT)
			if @file.stat.size == 0
				init_file(atime)
			else
				read_file
			end
		end

		def close
			@file.close
		end

		def append(atime, data, &block)
			reltime = atime - @atime
			if reltime <= @last_reltime
				reltime = @last_reltime+1
			end
			@last_reltime = reltime

			pos = get_offset

			r = Record.new(reltime, data)
			ref = RecordRef.new(reltime, pos)

			@file.pos = pos
			r.write(@file)
			noffset = @file.pos

			block.call

			@index << ref
			set_offset(noffset)

			reltime + @atime
		end

		def get(time)
			reltime = time - @atime

			while true
				# FIXME binary search
				ref = @index.find {|ref|
					ref.reltime > reltime
				}

				unless ref
					break
				end

				r = ref.read_body(@file)

				return r.data, r.reltime + @atime
			end

			return nil, reltime + @atime
		end

		private
		def init_file(atime)
			header = Header.new(atime, HEADER_SIZE)

			@file.pos = 0
			@file.write(header.dump)

			@atime = header.atime
			@index = []
			@last_reltime = 0
		end

		def read_file
			@file.pos = 0
			raw = @file.read(HEADER_SIZE)
			header = Header.load(raw)

			@atime = header.atime
			@index = []
			@last_reltime = 0

			pos = header.pos

			@file.pos = HEADER_SIZE
			while @file.pos < pos
				r = RecordRef.read(@file)
				break unless r
				@index << r
				@last_reltime = r.reltime
			end

			noffset = @file.pos

			set_offset(noffset)
		end

		def get_offset
			Header.read_offset(@file)
		end

		def set_offset(pos)
			Header.write_offset(@file, pos)
			pos
		end
	end

	def open(expr)
		@dir = expr
		atime = next_time
		# FIXME rotation
		@f = LogFile.new("#{@dir}/ulog-0000000001", atime)
	end

	def close
		@f.close
	end

	def append(data, &block)
		# FIXME rotation
		atime = next_time
		atime = @f.append(atime, data, &block)
		atime
	end

	def get(pos)
		# FIXME rotation
		@f.get(pos)
	end

	private
	def next_time
		# FIXME
		Time.now.to_i
	end
end


end


if $0 == __FILE__
	require 'msgpack'
	require 'stringio'
	include LS4


	puts "testing FileUpdateLog::Record ..."

	def check(a, b)
		if a.reltime != b.reltime ||
				a.data != b.data
			raise "test failed: expect #{a.inspect} but #{b.inspect}"
		end
	end

	src = []
	io = StringIO.new

	1000.times {|i|
		s = FileUpdateLog::Record.new(rand(i).to_i, "abc"*rand(i*5))
		s.write(io)
		src << s
	}

	io.pos = 0

	src.each {|s|
		r = FileUpdateLog::Record.read(io)
		check(s, r)
	}

	puts "ok"


	puts "testing FileUpdateLog ..."

	ulog = FileUpdateLog.new("./test/")
	begin

		pos = ulog.append("dummy") do
			true
		end

		src = []
		100.times {|i|
			data = "data#{rand(i)}"

			ulog.append(data) do
			end

			src << data
		}

		while true
			data, pos = ulog.get(pos)
			unless data
				break
			end

			s = src.shift
			if data != s
				raise "test failed: expect #{s.inspect} but #{data.inspect}"
			end
		end

		unless src.empty?
			raise "test failed: lost records"
		end

	ensure
		ulog.close
	end

	puts "ok"
end

