module MaxmainddbBuild
  module MaxmainddbVersion
    MAJOR = 1
    MINOR = 2
    MICRO = 0
    VERSION = [MAJOR, MINOR, MICRO]
  end

  module_function
  def local_maxminddb_base_dir
    File.join(File.dirname(__FILE__), "vendor")
  end

  def local_maxminddb_install_dir
    File.expand_path(File.join(local_maxminddb_base_dir, "local"))
  end

  def have_local_maxminddb?(package_name, major, minor, micro)
    return false unless File.exist?(File.join(local_maxminddb_install_dir, "lib"))

    prepend_pkg_config_path_for_local_maxminddb
    PKGConfig.have_package(package_name, major, minor, micro)
  end

  def prepend_pkg_config_path_for_local_maxminddb
    pkg_config_dir = File.join(local_maxminddb_install_dir, "lib", "pkgconfig")
    PKGConfig.add_path(pkg_config_dir)
  end

  def add_rpath_for_local_maxminddb
    lib_dir = File.join(local_maxminddb_install_dir, "lib")
    original_LDFLAGS = $LDFLAGS
    checking_for(checking_message("-Wl,-rpath is available")) do
      $LDFLAGS += " -Wl,-rpath,#{Shellwords.escape(lib_dir)}"
      available = try_compile("int main() {return 0;}")
      $LDFLAGS = original_LDFLAGS unless available
      available
    end
  end
end
