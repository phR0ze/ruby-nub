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
require_relative 'fileutils'

# Wrapper around system Arch Linux pacman
module Pacman
  extend self
  mattr_accessor(:path, :config, :sysroot, :mirrors, :repos, :arch)

  # Configure pacman for the given root
  # @param path [String] path where all pacman artifacts will be (i.e. logs, cache etc...)
  # @param config [String] config file path to use, note gets copied in
  # @param mirrors [Array] of mirror paths to use, mirror file name is expected to be the
  #                        name of the repo e.g. archlinux.mirrorlist
  # @param arch [String] capturing the pacman target architecture e.g. x86_64
  # @param sysroot [String] path to the system root to use
  def init(path, config, mirrors, arch:'x86_64', sysroot:nil)
    mirrors = [mirrors] if mirrors.is_a?(String)
    self.path = path
    self.arch = arch
    self.sysroot = sysroot
    self.config = File.join(path, File.basename(config))
    self.repos = mirrors.map{|x| File.basename(x, '.mirrorlist')}
    self.mirrors = mirrors.map{|x| File.join(path, File.basename(x))}

    # Validate incoming params
    Log.die("pacman path '#{path}' doesn't exist") unless Dir.exist?(path)
    Log.die("pacman config '#{config}' doesn't exist") unless File.exist?(config)
    Log.die("pacman sysroot '#{sysroot}' doesn't exist") if sysroot && !Dir.exist?(sysroot)

    # Copy in pacman files for use in target
    FileUtils.rm_rf(File.join(path, '.'))
    FileUtils.cp(config, path, preserve: true)
    FileUtils.cp(mirrors, path, preserve: true)

    # Update the given pacman config file to use the given path
    FileUtils.replace(self.config, /(Architecture = ).*/, "\\1#{self.arch}")
    # Leave DBPath set as /var/lib/pacman and copy out sync
    FileUtils.replace(self.config, /#(CacheDir\s+= ).*/, "\\1#{File.join(self.path, 'cache')}")
    FileUtils.replace(self.config, /#(LogFile\s+= ).*/, "\\1#{File.join(self.path, 'pacman.log')}")
    FileUtils.replace(self.config, /#(GPGDir\s+= ).*/, "\\1#{File.join(self.path, 'gnupg')}")
    FileUtils.replace(self.config, /#(HookDir\s+= ).*/, "\\1#{File.join(self.path, 'hooks')}")
    FileUtils.replace(self.config, /.*(\/.*mirrorlist).*/, "Include = #{self.path}\\1")

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
