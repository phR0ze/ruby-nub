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
  mattr_accessor(:path, :config, :sysroot, :mirrors, :repos, :arch, :env)

  # Configure pacman for the given root
  # @param path [String] path where all pacman artifacts will be (i.e. logs, cache etc...)
  # @param config [String] config file path to use, note gets copied in
  # @param mirrors [Array] of mirror paths to use, mirror file name is expected to be the
  #                        name of the repo e.g. archlinux.mirrorlist
  # @param arch [String] capturing the pacman target architecture e.g. x86_64
  # @param sysroot [String] path to the system root to use
  # @param env [Hash] of environment variables to set for session
  def init(path, config, mirrors, arch:'x86_64', sysroot:nil, env:nil)
    mirrors = [mirrors] if mirrors.is_a?(String)
    self.path = path
    self.arch = arch
    self.sysroot = sysroot
    self.config = File.join(path, File.basename(config))
    self.repos = mirrors.map{|x| File.basename(x, '.mirrorlist')}
    self.mirrors = mirrors.map{|x| File.join(path, File.basename(x))}

    # Validate incoming params
    Log.die("pacman config '#{config}' doesn't exist") unless File.exist?(config)

    # Copy in pacman files for use in target
    FileUtils.rm_rf(File.join(path, '.'))
    FileUtils.mkdir_p(File.join(self.path, 'db'))
    FileUtils.mkdir_p(self.sysroot) if self.sysroot && !Dir.exist?(self.sysroot)
    FileUtils.cp(config, path, preserve: true)
    FileUtils.cp(mirrors, path, preserve: true)

    # Update the given pacman config file to use the given path
    FileUtils.replace(self.config, /(Architecture = ).*/, "\\1#{self.arch}")
    FileUtils.replace(self.config, /#(DBPath\s+= ).*/, "\\1#{File.join(self.path, 'db')}")
    FileUtils.replace(self.config, /#(CacheDir\s+= ).*/, "\\1#{File.join(self.path, 'cache')}")
    FileUtils.replace(self.config, /#(LogFile\s+= ).*/, "\\1#{File.join(self.path, 'pacman.log')}")
    FileUtils.replace(self.config, /#(GPGDir\s+= ).*/, "\\1#{File.join(self.path, 'gnupg')}")
    FileUtils.replace(self.config, /#(HookDir\s+= ).*/, "\\1#{File.join(self.path, 'hooks')}")
    FileUtils.replace(self.config, /.*(\/.*mirrorlist).*/, "Include = #{self.path}\\1")

    # Initialize pacman keyring
    Sys.exec("pacman-key --config #{self.config} --init")
    Sys.exec("pacman-key --config #{self.config} --populate #{repos * ' '}")
  end

  # Update the pacman database
  def update
    cmd = "pacman -Sy"
    cmd += " --config #{self.config}" if self.config
    Sys.exec(cmd)
  end

  # Install the given packages
  # @param pkgs [Array] of packages to install
  # @param ignore [Array] of packages to ignore
  def install(pkgs, ignore:nil)
    cmd = []

    if self.sysroot
      cmd += ["pacstrap", "-GMc", self.sysroot, '--config', self.config]
    else
      cmd += ["pacman", "-S"]
    end

    # Ignore any packages called out
    ignore = [ignore] if ignore.is_a?(String)
    cmd += ["--ignore", "#{ignore * ','}"] if ignore && ignore.any?

    # Add packages to install
    cmd += ['--needed', *pkgs]

    # Execute if there are any packages given
    if pkgs.any?
      self.env ? Sys.exec(cmd, env:self.env) : Sys.exec(cmd)
    end
  end

  # Remove the given conflicting packages
  # @param pkgs [Array] of packages to remove
  def remove_conflict(pkgs)
    cmd = "pacman -Rn"
    cmd += " -r #{self.sysroot}" if self.sysroot
    cmd += " -d -d --noconfirm #{pkgs * ' '} &>/dev/null || true"
    Sys.exec(cmd)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
