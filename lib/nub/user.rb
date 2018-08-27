#!/usr/bin/env ruby
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

require 'etc'

# Some user related helper methods
module User
  extend self

  # Drop root privileges to original user
  # Only affects ruby commands not system commands
  # @returns [uid, gid] of root user
  def drop_privileges()
    uid = gid = nil

    if Process.uid.zero?
      uid, gid = Process.uid, Process.gid
      sudo_uid, sudo_gid = ENV['SUDO_UID'].to_i, ENV['SUDO_GID'].to_i
      Process::Sys.seteuid(sudo_uid)
      Process::Sys.setegid(sudo_gid)
    end

    return uid, gid
  end

  # Raise privileges if dropped earlier
  # Only affects ruby commands not system commands
  # @param uid [String] uid of user to assume
  # @param gid [String] gid of user to assume
  def raise_privileges(uid, gid)
    if uid and gid
      Process::Sys.seteuid(uid)
      Process::Sys.setegid(gid)
    end
  end


  # Check if the current user has root privileges
  def root?
    return Process.uid.zero?
  end

  # Get the current user taking into account sudo priviledges
  def name
    return Process.uid.zero? ? Etc.getpwuid(ENV['SUDO_UID'].to_i).name : ENV['USER']
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
