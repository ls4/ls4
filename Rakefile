require 'rake'
require 'rake/testtask'
require 'rake/clean'

begin
	require 'jeweler'
	Jeweler::Tasks.new do |gemspec|
		gemspec.name = "ls4"
		gemspec.summary = "LS4 - large-scale simple storage system"
		gemspec.author = "FURUHASHI Sadayuki"
		gemspec.email = "frsyuki@users.sourceforge.jp"
		gemspec.homepage = "http://ls4.sourceforge.net/"
		gemspec.has_rdoc = false
		gemspec.require_paths = ["lib"]
		gemspec.add_dependency "msgpack", ">= 0.4.4"
		gemspec.add_dependency "msgpack-rpc", ">= 0.4.3"
		gemspec.add_dependency "tokyocabinet", ">= 1.29"
		gemspec.add_dependency "tokyotyrant", ">= 1.13"
		gemspec.add_dependency "memcache-client", ">= 1.8.5"
		gemspec.add_dependency "rack", ">= 1.2.1"
		gemspec.test_files = Dir["test/**/*.rt"]
		gemspec.files = Dir["lib/**/*", "ext/**/*", "test/**/*.rb", "test/**/*.rt"] +
			%w[AUTHORS ChangeLog COPYING NOTICE README.rdoc]
		gemspec.extra_rdoc_files = %w[README.rdoc ChangeLog]
		gemspec.add_development_dependency('rspec')
	end
	Jeweler::GemcutterTasks.new
rescue LoadError
	puts "Jeweler not available. Install it with: gem install jeweler"
end

VERSION_FILE = "lib/ls4/version.rb"

file VERSION_FILE => ["VERSION"] do |t|
	version = File.read("VERSION").strip
	File.open(VERSION_FILE, "w") {|f|
		f.write <<EOF
module LS4

VERSION = '#{version}'

end
EOF
	}
end

task :default => [VERSION_FILE, :build]

task :test => ['test:unit','spec:unit']

