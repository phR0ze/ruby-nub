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

  # Check if the current user has root privileges
  def root?
    return Process.uid.zero?
  end

  # Get the real user taking into account sudo priviledges
  def name
    return Process.uid.zero? ? Etc.getpwuid(ENV['SUDO_UID'].to_i).name : ENV['USER']
  end

  # Correctly and permanently drops privileges
  # http://timetobleed.com/5-things-you-dont-know-about-user-ids-that-will-destroy-you/
  # requires you drop the group before the user and use a safe solution
  def drop_privileges!
    if Process.uid.zero?
      nobody = Etc.getpwnam('nobody')
      Process::Sys.setresgid(nobody.gid, nobody.gid, nobody.gid)
      Process::Sys.setresuid(nobody.uid, nobody.uid, nobody.uid)
    end
  end

  # Drop root privileges to original user
  # @param [Proc] optional block to execut in context of user
  # @returns [uid, gid] or result
  def drop_privileges
    result = nil
    uid = gid = nil

    # Drop privileges
    if Process.uid.zero?
      uid, gid = Process.uid, Process.gid
      user_uid = ENV['SUDO_UID'].to_i
      user_gid = ENV['SUDO_GID'].to_i
      Process::GID.grant_privilege(user_gid)
      Process::UID.grant_privilege(user_uid)
    end

    # Execute block if given
    begin
      result = Proc.new.call
      self.raise_privileges(uid, gid)
    rescue ArgumentError
      # No block given just return ids
      result = [uid, gid]
    rescue
      self.raise_privileges(uid, gid)
    end

    return result
  end

  # Raise privileges if dropped earlier
  # @param uid [String] uid of user to assume
  # @param gid [String] gid of user to assume
  def raise_privileges(uid, gid)
    if uid and gid
      Process::UID.grant_privilege(uid)
      Process::GID.grant_privilege(gid)
    end
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
