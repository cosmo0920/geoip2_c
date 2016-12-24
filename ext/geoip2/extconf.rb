require "mkmf"
require "shellwords"
require "open-uri"
require "uri"

require "pkg-config"

base_dir = Pathname(__FILE__).dirname.parent.parent.expand_path
$LOAD_PATH.unshift(base_dir.to_s)

require "maxminddb-build"

include MaxmainddbBuild

package_name = "libmaxminddb"
major, minor, micro = MaxmainddbVersion::VERSION

checking_for(checking_message("GCC")) do
  if macro_defined?("__GNUC__", "")
    $CFLAGS += " -Wall"
    true
  else
    false
  end
end

def win32?
  /cygwin|mingw|mswin/ =~ RUBY_PLATFORM
end

checking_for(checking_message("Win32 OS")) do
  win32 = win32?
  if win32
    binary_base_dir = base_dir + "vendor" + "local"
    pkg_config_dir = binary_base_dir + "lib" + "pkgconfig"
    PKGConfig.add_path(pkg_config_dir.to_s)
    PKGConfig.set_override_variable("prefix", binary_base_dir.to_s)
  end
  win32
end

def install_maxminddb_locally(major, minor, micro)
  FileUtils.mkdir_p(local_maxminddb_base_dir)

  Dir.chdir(local_maxminddb_base_dir) do
    build_maxminddb(major, minor, micro)
  end

  prepend_pkg_config_path_for_local_maxminddb
end

def build_maxminddb(major, minor, micro)
  build_maxminddb_from_tar_gz(major, minor, micro)
end

def build_maxminddb_from_tar_gz(major, minor, micro)
  tar_gz = "libmaxminddb-#{major}.#{minor}.#{micro}.tar.gz"
  url = "https://github.com/maxmind/libmaxminddb/releases/download/#{major}.#{minor}.#{micro}/#{tar_gz}"
  download(url)

  message("extracting...")
  if xsystem("tar xfz #{tar_gz}")
    message(" done\n")
  else
    message(" failed\n")
    exit(false)
  end

  maxminddb_source_dir = "libmaxminddb-#{major}.#{minor}.#{micro}"
  Dir.chdir(maxminddb_source_dir) do
    install_for_gnu_build_system(local_maxminddb_install_dir)
  end

  message("removing source...")
  FileUtils.rm_rf(maxminddb_source_dir)
  message(" done\n")

  message("removing source archive...")
  FileUtils.rm_rf(tar_gz)
  message(" done\n")
end

def download(url)
  message("downloading %s...", url)
  base_name = File.basename(url)
  if File.exist?(base_name)
    message(" skip (use downloaded file)\n")
  else
    open(url, "rb") do |input|
      File.open(base_name, "wb") do |output|
        while (buffer = input.read(1024))
          output.print(buffer)
        end
      end
    end
    message(" done\n")
  end
end

def install_local_maxminddb(package_name, major, minor, micro)
  unless have_local_maxminddb?(package_name, major, minor, micro)
    target_version = [major, minor, micro]
    install_maxminddb_locally(*target_version)
  end
  unless PKGConfig.have_package(package_name, major, minor, micro)
    exit(false)
  end
  add_rpath_for_local_maxminddb
end

def run_command(start_message, command)
  message(start_message)
  if xsystem(command)
    message(" done\n")
  else
    message(" failed\n")
    exit(false)
  end
end

def configure_command_line(prefix)
  command_line = ["./configure"]
  command_line << "--prefix=#{prefix}"
  command_line << "--disable-static"
  escaped_command_line = command_line.collect do |command|
    Shellwords.escape(command)
  end
  escaped_command_line.join(" ")
end

def guess_make
  env_make = ENV["MAKE"]
  return env_make if env_make

  candidates = ["gmake", "make"]
  candidates.each do |candidate|
    (ENV["PATH"] || "").split(File::PATH_SEPARATOR).each do |path|
      return candidate if File.executable?(File.join(path, candidate))
    end
  end

  "make"
end

def n_processors
  proc_file = "/proc/cpuinfo"
  if File.exist?(proc_file)
    File.readlines(proc_file).grep(/^processor/).size
  elsif /darwin/ =~ RUBY_PLATFORM
    `sysctl -n hw.ncpu`.to_i
  else
    1
  end
end

def install_for_gnu_build_system(install_dir)
  make = guess_make
  run_command("configuring...",
              configure_command_line(install_dir))
  run_command("building (maybe long time)...",
              "#{make} -j#{n_processors}")
  run_command("installing...",
              "#{make} install")
end

if win32?
  unless have_local_maxminddb?(package_name, major, minor, micro)
    install_local_maxminddb(package_name, major, minor, micro)
  end
else
  unless PKGConfig.have_package(package_name, major, minor, micro)
    install_local_maxminddb(package_name, major, minor, micro)
  end
end

dir_config("maxminddb")
have_header("maxminddb.h")
have_library("maxminddb")
have_func("rb_sym2str", "ruby.h")

$CFLAGS << " -std=c99"
# $CFLAGS << " -g -O0"

create_makefile("geoip2/geoip2")
