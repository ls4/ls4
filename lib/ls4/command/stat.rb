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
require 'msgpack/rpc'
require 'optparse'

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

CS_PARAMS = %w[
	nid address name rsid rsids location
]

DS_PARAMS = %w[
	read write delete items
	time uptime pid version
]

EXT_PARAMS = %w[
	state
]

ALL_PARAMS = CS_PARAMS + EXT_PARAMS + DS_PARAMS

DEFAULT_PARAMS = %w[
	nid address name read write delete time
]

conf = {
	:array  => false,
	:format => 'tsv',
	:only   => [],
}

op.banner = <<EOF
Usage: #{File.basename($0)} <cs address[:port]> [options] params...
params:
    nid     address    name      rsid    location
    state   time       uptime    pid     version
    read    write      delete    items
default params:
    #{DEFAULT_PARAMS.join(' ')}
options:
EOF

op.on('-a', '--array', 'print as arrays instead of a maps', TrueClass) {|b|
	conf[:array] = true
}

op.on('-o', '--only NID_OR_NAMES', 'get status of these servers only') {|s|
	only = s.split(',').map {|str|
		num = str.to_i
		if num.to_s == str
			num  # nid
		else
			str  # name
		end
	}
	conf[:only].concat(only)
}

op.on('-t', '--tsv', 'use Tab-Separated-Values format (default)', TrueClass) {|b|
	conf[:format] = 'tsv'
}

op.on('-j', '--json', 'use JSON format', TrueClass) {|b|
	conf[:format] = 'json'
}

op.on('-m', '--msgpack', 'use MessagePack format', TrueClass) {|b|
	conf[:format] = 'msgpack'
}

op.on('-y', '--yaml', 'use YAML format', TrueClass) {|b|
	conf[:format] = 'yaml'
}

begin
	op.parse!(ARGV)

	if ARGV.empty?
		usage nil
	end

	host, port = ARGV.shift.split(':',2)
	port ||= 18700

	ARGV.each {|arg|
		unless ALL_PARAMS.include?(arg)
			raise "unknown parameter: #{arg.dump}"
		end
	}
	params = ARGV

	if params.empty?
		params = DEFAULT_PARAMS
	end

rescue
	usage $!.to_s
end

sp = MessagePack::RPC::SessionPool.new
cs = sp.get_session(host, port)

Node = Struct.new('Node', *ALL_PARAMS.map{|s|s.to_sym})

nodes = cs.call(:stat, 'nodes').map {|nid,address,name,rsids,location|
	address = MessagePack::RPC::Address.load(address)
	n = Node.new
	n.nid = nid
	n.address = address.to_s
	n.name = name
	n.rsids = rsids
	n.rsid = rsids[0]
	n.location = location
	n
}.sort_by {|node|
	node.nid
}

only = conf[:only]
unless only.empty?
	nodes.select! {|n|
		only.include?(n.nid) || only.include?(n.name)
	}
end

if params.include?('state')
	fault_nids = cs.call(:stat, 'fault')
	nodes.each {|n|
		if fault_nids.include?(n.nid)
			n.state = 'FAULT'
		else
			n.state = 'active'
		end
	}
end

ds_params = params.select {|pa| DS_PARAMS.include?(pa) }
unless ds_params.empty?
	stats = nodes.map {|n|
		fs = []
		s = sp.get_session(*n.address.split(':',2))
		ds_params.each {|pa|
			case pa
			when "read"
				fs << s.call_async(:stat, 'cmd_read')
			when "write"
				fs << s.call_async(:stat, 'cmd_write')
			when "delete"
				fs << s.call_async(:stat, 'cmd_delete')
			when "items"
				fs << s.call_async(:stat, 'db_items')
			when "time"
				fs << s.call_async(:stat, 'time')
			when "uptime"
				fs << s.call_async(:stat, 'uptime')
			when "pid"
				fs << s.call_async(:stat, 'pid')
			when "version"
				fs << s.call_async(:stat, 'version')
			end
		}
		fs
	}.map {|fs|
		fs.map {|f|
			f.get rescue nil
		}
	}

	nodes.zip(stats) {|n,stat|
		ds_params.each {|pa|
			n.__send__(pa+"=", stat.shift)
		}
	}
end

if conf[:array]
	results = nodes.map {|n|
		params.map {|pa|
			n.__send__(pa)
		}
	}
else
	results = nodes.map {|n|
		h = []
		params.map {|pa|
			h << pa << n.__send__(pa)
		}
		Hash[*h]
	}
end

case conf[:format]
when 'tsv'
	if conf[:array]
		results.each {|a|
			$stdout.puts a.join("\t")
		}
	else
		$stdout.puts params.join("\t")
		results.each {|h|
			$stdout.puts h.values.join("\t")
		}
	end

when 'msgpack'
	$stdout.print results.to_msgpack

when 'yaml'
	require 'yaml'
	$stdout.print results.to_yaml

when 'json'
	require 'json'
	$stdout.print results.to_json
end

