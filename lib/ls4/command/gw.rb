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
require 'digest/md5'
require 'digest/sha1'
require 'csv'
require 'fileutils'
require 'cgi'
require 'ls4/lib/cclog'
require 'ls4/lib/ebus'
require 'ls4/lib/vbcode'
require 'ls4/logic/tsv_data'
require 'ls4/logic/weight'
require 'ls4/logic/fault_detector'
require 'ls4/logic/membership'
require 'ls4/logic/node'
require 'ls4/logic/okey'
require 'ls4/service/base'
require 'ls4/service/bus'
require 'ls4/service/process'
require 'ls4/service/rpc'
require 'ls4/service/rpc_gw'
require 'ls4/service/stat'
require 'ls4/service/stat_gw'
require 'ls4/service/config'
require 'ls4/service/config_gw'
require 'ls4/service/data_client'
require 'ls4/service/mds'
require 'ls4/service/mds_ha'
require 'ls4/service/mds_tt'
require 'ls4/service/mds_memcache'
require 'ls4/service/mds_cache'
require 'ls4/service/mds_cache_mem'
require 'ls4/service/mds_cache_memcached'
require 'ls4/service/gateway'
require 'ls4/service/gateway_ro'
require 'ls4/service/gw_http'
require 'ls4/service/sync'
require 'ls4/service/heartbeat'
require 'ls4/service/weight'
require 'ls4/service/balance'
require 'ls4/service/master_select'
require 'ls4/service/membership'
require 'ls4/service/time_check'
require 'ls4/service/log'
require 'ls4/default'
require 'ls4/version'
require 'optparse'

include LS4

conf = GWConfigService.init

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

store_path = nil

listen_host = '0.0.0.0'
listen_port = GW_DEFAULT_PORT

read_only_gw = false

op.on('-c', '--cs ADDRESS', "address of config server") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = CS_DEFAULT_PORT if port == 0
	conf.cs_address = Address.new(host, port)
end

op.on('-p', '--port PORT', "listen port") do |addr|
	if addr.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = GW_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-l', '--listen HOST', "listen address") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
		port = GW_DEFAULT_PORT if port == 0
		listen_host = host
		listen_port = port
	else
		listen_host = addr
	end
end

op.on('-t', '--http PORT', "http listen port") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
	else
		host = '0.0.0.0'
		port = addr.to_i
	end
	conf.http_gateway_address = Address.new(host, port)
end

op.on('--http-error-page PATH', 'path to eRuby template file') do |path|
	conf.http_gateway_error_template_file = path
end

op.on('-R', '--read-only', "read-only mode", TrueClass) do |b|
	read_only_gw = b
end

op.on('-N', '--read-only-name NAME', "read-only mode using the version name") do |name|
	read_only_gw = true
	conf.read_only_version = name
end

op.on('-T', '--read-only-time TIME', "read-only mode using the time", Integer) do |time|
	read_only_gw = true
	conf.read_only_version = time
end

op.on('-L', '--location STRING', "enable location-aware master selection") do |str|
	conf.self_location = str
end

op.on('-s', '--store PATH', "path to base directory") do |path|
	store_path = path
end

op.on('--fault_store PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('--membership_store PATH', "path to membership status file") do |path|
	conf.membership_path = path
end

op.on('--weight_store PATH', "path to weight status file") do |path|
	conf.weight_path = path
end

op.on('-o', '--log PATH') do |path|
	conf.log_path = path
end

op.on('-v', '--verbose', "show debug messages", TrueClass) do |b|
	$log.level = 1 if b
end

op.on('--trace', "show debug and trace messages", TrueClass) do |b|
	$log.level = 0 if b
end

op.on('--color-log', "force to enable color log", TrueClass) do |b|
	$log.enable_color
end


begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

	unless conf.cs_address
		raise "--cs option is required"
	end

	if store_path
		FileUtils.mkdir_p(store_path)
	end

	if !conf.fault_path && store_path
		conf.fault_path = File.join(store_path, "fault")
	end

	if !conf.membership_path && store_path
		conf.membership_path = File.join(store_path, "membership")
	end

	if !conf.weight_path && store_path
		conf.weight_path = File.join(store_path, "weight")
	end

rescue
	usage $!.to_s
end


ProcessService.init
LogService.open!
SyncClientService.init
HeartbeatClientService.init
RoutRobinWeightBalanceService.init
WeightMemberService.init
if conf.self_location
	LocationAwareMasterSelectService.init
else
	FlatMasterSelectService.init
end
MembershipClientService.init
DataClientService.init
if read_only_gw
	ReadOnlyGatewayService.init
else
	GatewayService.init
end
if conf.http_gateway_address
	HTTPGatewayService.open!
end
GWStatService.init
MDSService.init
MDSCacheService.init
CachedMDSService.init
TimeCheckService.init

LogService.instance.log_event_bus

ProcessBus.run

TimeCheckService.instance.check_blocking! rescue nil
SyncClientService.instance.sync_blocking! rescue nil
#HeartbeatClientService.instance.heartbeat_blocking! rescue nil

net = ProcessBus.serve_rpc(GWRPCService.instance)
net.listen(listen_host, listen_port)

$log.info "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown
