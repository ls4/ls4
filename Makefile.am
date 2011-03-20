
BUILD_TMP = build-tmp

nobase_pkgdata_SCRIPTS = \
	bin/ls4-cs \
	bin/ls4-ds \
	bin/ls4-gw \
	bin/ls4-standalone \
	bin/ls4cmd \
	bin/ls4ctl \
	bin/ls4rpc \
	bin/ls4stat \
	bin/ls4top \
	lib/ls4/default.rb \
	lib/ls4/command/cmd.rb \
	lib/ls4/command/cs.rb \
	lib/ls4/command/ctl.rb \
	lib/ls4/command/ds.rb \
	lib/ls4/command/gw.rb \
	lib/ls4/command/standalone.rb \
	lib/ls4/command/rpc.rb \
	lib/ls4/command/stat.rb \
	lib/ls4/command/top.rb \
	lib/ls4/lib/cclog.rb \
	lib/ls4/lib/ebus.rb \
	lib/ls4/lib/vbcode.rb \
	lib/ls4/logic/fault_detector.rb \
	lib/ls4/logic/membership.rb \
	lib/ls4/logic/node.rb \
	lib/ls4/logic/okey.rb \
	lib/ls4/logic/tsv_data.rb \
	lib/ls4/logic/weight.rb \
	lib/ls4/service/balance.rb \
	lib/ls4/service/base.rb \
	lib/ls4/service/bus.rb \
	lib/ls4/service/config.rb \
	lib/ls4/service/config_cs.rb \
	lib/ls4/service/config_ds.rb \
	lib/ls4/service/config_gw.rb \
	lib/ls4/service/data_client.rb \
	lib/ls4/service/data_server.rb \
	lib/ls4/service/data_server_url.rb \
	lib/ls4/service/gateway.rb \
	lib/ls4/service/gateway_ro.rb \
	lib/ls4/service/gw_http.rb \
	lib/ls4/service/heartbeat.rb \
	lib/ls4/service/log.rb \
	lib/ls4/service/master_select.rb \
	lib/ls4/service/mds.rb \
	lib/ls4/service/mds_ha.rb \
	lib/ls4/service/mds_tt.rb \
	lib/ls4/service/mds_tc.rb \
	lib/ls4/service/mds_memcache.rb \
	lib/ls4/service/mds_cache.rb \
	lib/ls4/service/mds_cache_mem.rb \
	lib/ls4/service/mds_cache_memcached.rb \
	lib/ls4/service/membership.rb \
	lib/ls4/service/process.rb \
	lib/ls4/service/rpc.rb \
	lib/ls4/service/rpc_cs.rb \
	lib/ls4/service/rpc_ds.rb \
	lib/ls4/service/rpc_gw.rb \
	lib/ls4/service/rts.rb \
	lib/ls4/service/rts_file.rb \
	lib/ls4/service/rts_memory.rb \
	lib/ls4/service/slave.rb \
	lib/ls4/service/stat.rb \
	lib/ls4/service/stat_cs.rb \
	lib/ls4/service/stat_ds.rb \
	lib/ls4/service/stat_gw.rb \
	lib/ls4/service/storage.rb \
	lib/ls4/service/storage_dir.rb \
	lib/ls4/service/sync.rb \
	lib/ls4/service/time_check.rb \
	lib/ls4/service/ulog.rb \
	lib/ls4/service/ulog_file.rb \
	lib/ls4/service/ulog_memory.rb \
	lib/ls4/service/weight.rb \
	lib/ls4/version.rb \
	test/01_add_get_remove.rt \
	test/02_read.rt \
	test/03_getd_readd.rt \
	test/04_version_time.rt \
	test/05_version_name.rt \
	test/06_http_get_set_remove_1.rt \
	test/07_http_get_set_remove_2.rt \
	test/08_read_only_time.rt \
	test/09_read_only_name.rt \
	test/10_http_get_set_remove_3.rt \
	test/11_mds_cache_memcached.rt \
	test/12_mds_cache_local_memory.rt \
	test/13_memcache_mds.rt \
	test/14_delete.rt \
	test/15_standalone.rt \
	test/chukan.rb \
	test/common.rb

bin_SCRIPTS = \
	$(BUILD_TMP)/ls4-cs \
	$(BUILD_TMP)/ls4-ds \
	$(BUILD_TMP)/ls4-gw \
	$(BUILD_TMP)/ls4-standalone \
	$(BUILD_TMP)/ls4cmd \
	$(BUILD_TMP)/ls4ctl \
	$(BUILD_TMP)/ls4rpc \
	$(BUILD_TMP)/ls4stat \
	$(BUILD_TMP)/ls4top

EXTRA_DIST = \
	$(nobase_pkgdata_SCRIPTS) \
	Rakefile \
	VERSION \
	README.md \
	README.ja.md

$(bin_SCRIPTS):
	mkdir -p `dirname $@`
	$(RUBY) -e "puts '#!'+File.expand_path('`which $(RUBY)`')" > "$@.tmp"
	echo "\$$LOAD_PATH << '$(pkgdatadir)/lib'" >> "$@.tmp"
	echo "begin" >> "$@.tmp"
	echo "require 'rubygems'" >> "$@.tmp"
	echo "rescue LoadError" >> "$@.tmp"
	echo "end" >> "$@.tmp"
	echo "load '$(pkgdatadir)/bin/`basename $@`'" >> "$@.tmp"
	chmod 755 "$@.tmp"
	mv "$@.tmp" "$@"

.PHONY: $(bin_SCRIPTS)

HTML_DOCS = \
	doc/index.html \
	doc/index.ja.html \
	doc/api.html \
	doc/api.ja.html \
	doc/arch.html \
	doc/arch.ja.html \
	doc/build.html \
	doc/build.ja.html \
	doc/command.html \
	doc/command.ja.html \
	doc/devel.html \
	doc/devel.ja.html \
	doc/faq.html \
	doc/faq.ja.html \
	doc/fault.html \
	doc/fault.ja.html \
	doc/howto.html \
	doc/howto.ja.html \
	doc/howto/nginx.html \
	doc/howto/nginx.ja.html \
	doc/install.html \
	doc/install.ja.html \
	doc/operation.html \
	doc/operation.ja.html \
	doc/plugin.html \
	doc/plugin.ja.html

MOSTLYCLEANFILES = \
	$(bin_SCRIPTS) \
	$(HTML_DOCS)

.md.html:
	ruby doc/erbdoc.rb $< $@.tmp
	mv $@.tmp $@

$(HTML_DOCS): doc/erbdoc.rb doc/doc.erb

htmldoc: $(HTML_DOCS)

