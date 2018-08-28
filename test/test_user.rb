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

require 'minitest/autorun'
require_relative '../lib/nub/log'
require_relative '../lib/nub/user'

class TestUser < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
  end

  def test_root?
    assert(!User.root?)
  end

  def test_name
    refute_equal('root', User.name)
  end

  def test_drop_privileges!
    uid, gid = Process.uid, Process.gid
    User.drop_privileges!
    assert_equal(uid, Process.uid)
    assert_equal(gid, Process.gid)
  end

  def test_drop_privileges_user
    uid, gid = User.drop_privileges
    assert_nil(uid)
    assert_nil(gid)
    ruid, rgid = Process.uid, Process.gid
    refute_equal(0, ruid)
    refute_equal(0, rgid)
    refute_equal(uid, ruid)
    refute_equal(gid, ruid)
  end

  def test_drop_privileges_sudo_mock
    uid = ENV['SUDO_UID'] = Process.uid.to_s
    gid = ENV['SUDO_GID'] = Process.gid.to_s

    validate_gid_params = ->(x) { assert_equal(gid.to_i, x)}
    validate_uid_params = ->(x) { assert_equal(uid.to_i, x)}

    Process.stub(:uid, 0) {
      Process.stub(:gid, 0) {
        Process::GID.stub(:grant_privilege, validate_gid_params) {
          Process::UID.stub(:grant_privilege, validate_uid_params) {
            assert_equal([0, 0], User.drop_privileges)
          }
        }
      }
    }
    ENV['SUDO_UID'] = nil
    ENV['SUDO_GID'] = nil
  end

  def test_drop_privileges_sudo_mock_block
    uid = ENV['SUDO_UID'] = Process.uid.to_s
    gid = ENV['SUDO_GID'] = Process.gid.to_s

    validate_gid_params = ->(x) { assert_equal(gid.to_i, x)}
    validate_uid_params = ->(x) { assert_equal(uid.to_i, x)}

    Process.stub(:uid, 0) {
      Process.stub(:gid, 0) {
        Process::GID.stub(:eid, validate_gid_params) {
          Process::UID.stub(:eid, validate_uid_params) {
            User.stub(:raise_privileges, true) {
              User.drop_privileges{ }
            }
          }
        }
      }
    }
    ENV['SUDO_UID'] = nil
    ENV['SUDO_GID'] = nil
  end

  def test_raise_privileges
    Process::GID.stub(:grant_privilege, ->(x){assert_equal(999, x)}) {
      Process::UID.stub(:grant_privilege, ->(x){assert_equal(888, x)}) {
        User.raise_privileges(888, 999)
      }
    }
  end

#  def test_drop_raise_sudo
#    user_uid = ENV['SUDO_UID'].to_i
#    user_gid = ENV['SUDO_GID'].to_i
#    refute_equal(0, user_uid)
#    refute_equal(0, user_gid)
#
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#    uid, gid = User.drop_privileges
#    refute_equal(0, Process::UID.eid)
#    refute_equal(0, Process::GID.eid)
#    User.raise_privileges(uid, gid)
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#  end
#
#  def test_drop_raise_sudo_blocks
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#    User.drop_privileges{
#      refute_equal(0, Process::UID.eid)
#      refute_equal(0, Process::GID.eid)
#    }
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#  end
#
#  def test_drop_raise_sudo_blocks_fail
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#    User.drop_privileges{
#      refute_equal(0, Process::UID.eid)
#      refute_equal(0, Process::GID.eid)
#      raise
#    }
#    assert_equal(0, Process::UID.eid)
#    assert_equal(0, Process::GID.eid)
#  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
