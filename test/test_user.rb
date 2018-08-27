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
require_relative '../lib/nub/user'

class TestUser < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
  end

  def test_drop_privileges
    ENV['SUDO_UID'] = "888"
    ENV['SUDO_GID'] = "999"

    validate_seteuid_params = ->(x) { assert_equal(888, x)}
    validate_setegid_params = ->(x) { assert_equal(999, x)}

    Process.stub(:uid, 0) {
      Process.stub(:gid, 0) {
        Process::Sys.stub(:seteuid, validate_seteuid_params) {
          Process::Sys.stub(:setegid, validate_setegid_params) {
            assert_equal([0, 0], User.drop_privileges)
          }
        }
      }
    }
  end

  def test_raise_privileges
    Process::Sys.stub(:seteuid, ->(x){assert_equal(888, x)}) {
      Process::Sys.stub(:setegid, ->(x){assert_equal(999, x)}) {
        User.raise_privileges(888, 999)
      }
    }
  end

  def test_root?
    assert(!User.root?)
  end

  def test_name
    assert(User.name != 'root')
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
