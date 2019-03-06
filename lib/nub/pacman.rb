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
  mattr_accessor(:path, :sysroot, :config, :mirrors, :repos, :arch,
    :env, :log, :db_path, :gpg_path, :hooks_path, :cache_path)

  # Configure pacman for the given root
  # @param path [String] is the path on the host for pacman
  # @param sysroot [String] path to the system root to use
  # @param config [String] config file path to use, note gets copied in
  # @param mirrors [Array] of mirror paths to use, mirror file name is expected to be the
  #                        name of the repo e.g. archlinux.mirrorlist
  # @param arch [String] capturing the pacman target architecture e.g. x86_64
  # @param env [Hash] of environment variables to set for session
  def init(path, sysroot, config, mirrors, arch:'x86_64', env:nil)

    # All configs are on the sysroot except config and cache
    mirrors = [mirrors] if mirrors.is_a?(String)
    self.path = path
    self.arch = arch
    self.env = env
    self.sysroot = sysroot
    self.log = File.join(sysroot, 'var/log/pacman.log')
    self.db_path = File.join(self.sysroot, 'var/lib/pacman')
    self.gpg_path = File.join(self.sysroot, 'etc/pacman.d/gnupg')
    self.hooks_path = File.join(self.sysroot, 'etc/pacman.d/hooks')
    self.repos = mirrors.map{|x| File.basename(x, '.mirrorlist')}
    mirrors_path = File.join(self.sysroot, 'etc/pacman.d')
    self.mirrors = mirrors.map{|x| File.join(mirrors_path, File.basename(x))}

    # Config and cache are kept separate from the sysroot
    self.config = File.join(self.path, File.basename(config))
    self.cache_path = File.join(self.path, 'cache')

    # Validate incoming params
    Log.die("pacman config '#{config}' doesn't exist") unless File.exist?(config)

    # Copy in pacman files for use in target
    FileUtils.mkdir_p(self.db_path)
    FileUtils.mkdir_p(self.gpg_path)
    FileUtils.mkdir_p(self.hooks_path)
    FileUtils.mkdir_p(self.cache_path)
    FileUtils.cp(config, self.config, preserve: true)
    FileUtils.cp(mirrors, mirrors_path, preserve: true)

    # Update the given pacman config file to use the given path
    FileUtils.replace(self.config, /(Architecture = ).*/, "\\1#{self.arch}")
    FileUtils.replace(self.config, /#(DBPath\s+= ).*/, "\\1#{self.db_path}")
    FileUtils.replace(self.config, /#(CacheDir\s+= ).*/, "\\1#{self.cache_path}")
    FileUtils.replace(self.config, /#(LogFile\s+= ).*/, "\\1#{self.log}")
    FileUtils.replace(self.config, /#(GPGDir\s+= ).*/, "\\1#{self.gpg_path}")
    FileUtils.replace(self.config, /#(HookDir\s+= ).*/, "\\1#{self.hooks_path}")
    FileUtils.replace(self.config, /.*(\/.*mirrorlist).*/, "Include = #{mirrors_path}\\1")

    # Initialize pacman keyring
    if !File.exist?(File.join(self.gpg_path, 'trustdb.gpg'))
      Sys.exec("pacman-key --config #{self.config} --init")
      Sys.exec("pacman-key --config #{self.config} --populate #{repos * ' '}")
    end
  end

  # Update the pacman database
  def update
    cmd = "pacman -Sy"
    cmd += " --config #{self.config}" if self.config
    Sys.exec(cmd)
  end

  # Install the given packages
  # @param pkgs [Array] of packages to install
  # @param flags [Array] of params to pass into pacman
  def install(pkgs, flags:nil)
    if pkgs && pkgs.any?
      cmd = []

      if self.sysroot
        cmd += ["pacstrap", "-c", "-M", self.sysroot, '--config', self.config]
      else
        cmd += ["pacman", "-S"]
      end

      # Add user flags
      cmd += flags if flags

      # Add packages to install
      cmd += ['--needed', *pkgs]

      # Execute
      self.env ? Sys.exec(cmd, env:self.env) : Sys.exec(cmd)
    end
  end

  # Remove the given conflicting packages
  # @param pkgs [Array] of packages to remove
  def remove_conflict(pkgs)
    if pkgs && pkgs.any?
      cmd = "pacman -Rn"
      cmd += " -r #{self.sysroot}" if self.sysroot
      cmd += " -d -d --noconfirm #{pkgs * ' '} &>/dev/null || true"
      Sys.exec(cmd)
    end
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
