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
require 'ls4/service/rpc_ds'
require 'ls4/service/stat'
require 'ls4/service/stat_gw'
require 'ls4/service/stat_ds'
require 'ls4/service/config'
require 'ls4/service/config_gw'
require 'ls4/service/config_ds'
require 'ls4/service/data_server'
require 'ls4/service/data_server_url'
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
require 'ls4/service/rts'
require 'ls4/service/rts_file'
require 'ls4/service/rts_memory'
require 'ls4/service/slave'
require 'ls4/service/storage'
require 'ls4/service/storage_dir'
require 'ls4/service/ulog'
require 'ls4/service/ulog_file'
require 'ls4/service/ulog_memory'
require 'ls4/service/time_check'
require 'ls4/service/log'
require 'ls4/default'
require 'ls4/version'
require 'optparse'

include LS4

conf = DSConfigService.init

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = '0.0.0.0'
listen_port = nil

read_only_gw = false

op.on('-c', '--cs ADDRESS', "address of config server (required)") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = CS_DEFAULT_PORT if port == 0
	conf.cs_address = Address.new(host, port)
end

op.on('-i', '--nid ID', Integer, "unieque node id (required)") do |nid|
	conf.self_nid = nid
end

op.on('-n', '--name NAME', "human-readable node name (required)") do |name|
	conf.self_name = name
end

op.on('-a', '--address ADDRESS[:PORT]', "address of this node (required)") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	if port != 0
		listen_port = port
	else
		port = DS_DEFAULT_PORT
	end
	conf.self_address = Address.new(host, port)
end

op.on('-l', '--listen HOST[:PORT]', "listen address") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
		if port != 0
			listen_port = port
		end
		listen_host = host
	else
		listen_host = addr
	end
end

op.on('-g', '--rsid IDs', "replica-set IDs to join (required)") do |ids|
	conf.self_rsids = ids.split(',').map {|id| id.to_i }
end

op.on('-L', '--location STRING', "location of this node") do |str|
	conf.self_location = str
end

op.on('-s', '--store PATH', "path to storage directory (required)") do |path|
	conf.storage_path = path
end

op.on('-u', '--ulog PATH', "path to update log directory") do |path|
	conf.ulog_path = path
end

op.on('-r', '--rts PATH', "path to relay timestamp directory") do |path|
	conf.rts_path = path
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

op.on('--http-redirect-port PORT', Integer) do |port|
	conf.http_redirect_port = port
end

op.on('--http-redirect-path FORMAT') do |format|
	conf.http_redirect_path_format = format
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

op.on('--fault_store PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('--membership_store PATH', "path to membership status file") do |path|
	conf.membership_path = path
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

	unless conf.self_nid
		raise "--nid option is required"
	end

	unless conf.self_name
		raise "--name option is required"
	end

	unless conf.self_address
		raise "--address option is required"
	end

	unless conf.self_rsids
		raise "--rsid option is required"
	end

	unless conf.cs_address
		raise "--cs option is required"
	end

	unless conf.storage_path
		raise "--store option is required"
	end

	FileUtils.mkdir_p(conf.storage_path)

	unless conf.ulog_path
		conf.ulog_path = conf.storage_path
		#raise "--ulog option is required"
	end

	unless conf.rts_path
		conf.rts_path = conf.storage_path
		#raise "--rts option is required"
	end

	unless conf.fault_path
		conf.fault_path = File.join(conf.storage_path, "fault")
	end

	unless conf.membership_path
		conf.membership_path = File.join(conf.storage_path, "membership")
	end

	unless conf.weight_path
		conf.weight_path = File.join(conf.storage_path, "weight")
	end

	if conf.http_redirect_path_format && !conf.http_redirect_port
		$log.warn "--http-redirect-port option is ignored"
	end

	listen_port ||= DS_DEFAULT_PORT

rescue
	usage $!.to_s
end


ProcessService.init
LogService.open!
SyncClientService.init
HeartbeatMemberService.init
RoutRobinWeightBalanceService.init
WeightMemberService.init
if conf.self_location.empty?
	FlatMasterSelectService.init
else
	LocationAwareMasterSelectService.init
end
MembershipMemberService.init
DataClientService.init
if read_only_gw
	ReadOnlyGatewayService.init
else
	GatewayService.init
end
if conf.http_gateway_address
	HTTPGatewayService.open!
end
StorageSelector.open!
UpdateLogSelector.open!
RelayTimeStampSelector.open!
SlaveService.init
DataServerService.init
DataServerURLService.init
DSStatService.init
MDSService.init
MDSCacheService.init
CachedMDSService.init
TimeCheckService.init

LogService.instance.log_event_bus

ProcessBus.run

TimeCheckService.instance.check_blocking! rescue nil
SyncClientService.instance.sync_blocking! rescue nil
MembershipMemberService.instance.register_self_blocking! rescue nil
#HeartbeatMemberService.instance.heartbeat_blocking! rescue nil

net = ProcessBus.serve_rpc(DSRPCService.instance)
net.listen(listen_host, listen_port)

$log.info "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown

