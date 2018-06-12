#MIT License
#Copyright (c) 2018 phR0ze
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

require 'fileutils'
require_relative 'log'
require_relative 'sys'
require_relative 'module'

# Wrapper around system Arch Linux pacman
module Pacman
  extend self
  mattr_accessor(:path, :config, :sysroot)

  # Configure pacman for the given root
  # @param path [String] path where all pacman artifacts will be (i.e. logs, cache etc...)
  # @param config [String] config file path to use, note gets copied in
  # @param sysroot [String] path to the system root to use
  def init(path, config, sysroot)
    self.path = path
    self.sysroot = sysroot
    self.config = File.join(path, File.basename(config))

    # Validate incoming params
    Log.die("pacman path '#{path}' doesn't exist") unless Dir.exist?(path)
    Log.die("pacman sysroot '#{sysroot}' doesn't exist") unless Dir.exist?(sysroot)
    Log.die("pacman config file '#{config}' doesn't exist") unless File.exist?(config)

    # Update the given pacman config file to use the given path
    FileUtils.rm_rf(File.join(path, '.'))
    FileUtils.cp(config, path, preserve: true)
    
    Sys.exec("cp -a #{@pacman_src_mirrors} #{@pacman_path}")
    Fedit.replace(@pacman_conf, /(Architecture = ).*/, "\\1#{@vars.arch}")
    # Leave DBPath set as /var/lib/pacman and copy out sync
    Fedit.replace(@pacman_conf, /#(CacheDir\s+= ).*/, "\\1#{File.join(@pacman_path, 'cache')}")
    Fedit.replace(@pacman_conf, /#(LogFile\s+= ).*/, "\\1#{File.join(@pacman_path, 'pacman.log')}")
    Fedit.replace(@pacman_conf, /#(GPGDir\s+= ).*/, "\\1#{File.join(@pacman_path, 'gnupg')}")
    Fedit.replace(@pacman_conf, /#(HookDir\s+= ).*/, "\\1#{File.join(@pacman_path, 'hooks')}")
    Fedit.replace(@pacman_conf, /.*(\/.*mirrorlist).*/, "Include = #{@pacman_path}\\1")

    repos = Dir[File.join(@pacman_path, "*.mirrorlist")].map{|x| File.basename(x, '.mirrorlist')}
    Sys.exec("pacman-key --config #{@pacman_conf} --init")
    Sys.exec("pacman-key --config #{@pacman_conf} --populate #{repos * ' '}")

    # Initialize pacman keyring
    #Sys.exec("pacman-key --config #{self.config} --init")
    #Sys.exec("pacman-key --config #{self.config} --populate #{repos * ' '}")
  end

  # Update the pacman database
  def update
    success = false
    while not success
      begin
        cmd = "pacman -Sy"
        cmd += " --sysroot #{self.sysroot}" if self.sysroot
        Sys.exec(cmd)
        success = true
      rescue Exception => e
        puts(e.message)
      end
    end
  end

  # Install the given packages
  # @param pkgs [Array] List of packages to install
  def install()
    puts("Pacstrap package installs for '#{deployment}'...".colorize(:cyan))
    cmd = ['pacstrap', '-GMc', deployment_work, '--config', @pacman_conf, '--needed', *apps[:reg]]
    cmd += ['--ignore', apps[:ignore] * ','] if apps[:ignore].any?
    !puts("Error: Failed to install packages correctly".colorize(:red)) and
      exit unless Sys.exec(cmd, env:@proxyenv)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
