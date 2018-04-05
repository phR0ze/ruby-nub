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

#require 'minitest/autorun'
require_relative '../lib/nub/sys'
require_relative '../lib/nub/string'

class TestSys < Minitest::Test

  def test_env_die_when_not_exist
    assert_nil(Sys.env('FOO_BAR', required:false))
    capture = Sys.capture{ assert_raises(SystemExit){ Sys.env('FOO_BAR') }}
    assert_equal("Error: FOO_BAR env variable is required!\n", capture.stdout.strip_color)
  end

  def test_caller_filename
    assert_equal("test.rb", Sys.caller_filename)
  end

  def test_capture
    capture = Sys.capture{ puts("test") }
    assert_equal("test\n", capture.stdout)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
