require "bundler/gem_tasks"
require "bundler/setup"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

require "rake/extensiontask"

task :build => :compile

spec = eval(File.read("geoip2_c.gemspec"))

# add your default gem packing task
Gem::PackageTask.new(spec) do |pkg|
end

Rake::ExtensionTask.new("geoip2", spec) do |ext|
  ext.lib_dir = "lib/geoip2"
  unless RUBY_PLATFORM =~ /mswin|mingw/
    ext.cross_compile = true
    ext.cross_platform = ['x86-mingw32', 'x64-mingw32']
  end
end

# Note that this rake-compiler-dock rake task dose not support bundle install(1) --path option.
# Please use bundle install instead when you execute this rake task.
namespace :build do
  desc 'Build gems for Windows per rake-compiler-dock'
  task :windows do
    require 'rake_compiler_dock'
    RakeCompilerDock.sh <<-CROSS
      bundle
      rake cross native gem RUBY_CC_VERSION='2.1.6:2.2.2:2.3.0'
    CROSS
  end
end

task :default => [:clobber, :compile, :test]
