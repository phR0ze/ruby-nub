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
require_relative '../lib/nub/sys'
require_relative '../lib/nub/config'

class TestConfig < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
  end

  def test_config_sidecar_config
    path = File.expand_path(File.join(File.dirname(__FILE__), 'foo.conf'))
    File.stub(:exists?, true) {
      Sys.capture{
        assert_raises(SystemExit){ Config.init('foo.conf') }
        assert_equal(path, Config.path)
      }
    }
  end

  def test_init
    Config.init('foo.bar')
    assert_equal(Config.path, "/home/#{ENV['USER']}/.config/foo.bar")
    assert(!Config.exists?)
  end

  def test_modifications
    Config.init('foofoo.yml')
    Config['vpns'] = ['foo1', 'foo2']
    assert_equal(Config['vpns'], ['foo1', 'foo2'])
    File.stub(:write, nil){ Config.save }
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
