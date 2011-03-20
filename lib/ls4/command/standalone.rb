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
require 'ls4/service/rpc_cs'
require 'ls4/service/stat'
require 'ls4/service/stat_gw'
require 'ls4/service/stat_ds'
require 'ls4/service/config'
require 'ls4/service/config_gw'
require 'ls4/service/config_ds'
require 'ls4/service/config_cs'
require 'ls4/service/data_server'
require 'ls4/service/data_server_url'
require 'ls4/service/data_client'
require 'ls4/service/mds'
require 'ls4/service/mds_ha'
require 'ls4/service/mds_tt'
require 'ls4/service/mds_tc'
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
mds_uri = nil
mds_cache_uri = ""

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = '0.0.0.0'
listen_port = DS_DEFAULT_PORT

read_only_gw = false

op.on('-p', '--port PORT', "listen port") do |addr|
	if addr.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = DS_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-l', '--listen HOST', "listen address") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
		port = DS_DEFAULT_PORT if port == 0
		listen_host = host
		listen_port = port
	else
		listen_host = addr
	end
end

op.on('-m', '--mds EXPR', "address of metadata servers") do |s|
	mds_uri = s
end

op.on('-M', '--mds-cache EXPR', "address of metadata cache servers") do |s|
	mds_cache_uri = s
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

	conf.self_address = Address.new('127.0.0.1', listen_port)
	conf.cs_address = conf.self_address

	conf.self_nid = 1
	conf.self_name = "standalone"
	conf.self_rsids = [1]

	a = conf.self_address.host
	if a.include?('.')
		s = a.split('.')[0,3].map{|v4| "%03d" % v4.to_i }.join('.')
	else
		s = a.split(':')[0,4].map{|v6| "%04x" % v6.to_i(16) }.join(':')
	end
	conf.self_location = "subnet-#{s}"

	unless conf.storage_path
		raise "--store option is required"
	end

	unless mds_uri
		mds_uri = "local:#{conf.storage_path}/mds.tct"
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

rescue
	usage $!.to_s
end


ProcessService.init
LogService.open!
StandaloneSyncService.init
RoutRobinWeightBalanceService.init
WeightMemberService.init
if conf.self_location.empty?
	FlatMasterSelectService.init
else
	LocationAwareMasterSelectService.init
end
StandaloneMembershipService.init
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

StandaloneMembershipService.instance.rpc_add_node(conf.self_nid, conf.self_address, conf.self_name, conf.self_rsids, conf.self_location)
MDSService.instance.reopen(mds_uri)
MDSCacheService.instance.reopen(mds_cache_uri) if mds_cache_uri

net = ProcessBus.serve_rpc(DSRPCService.instance)
net.listen(listen_host, listen_port)

$log.info "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown

