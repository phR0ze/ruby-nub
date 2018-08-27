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
require_relative '../lib/nub/core'
require_relative '../lib/nub/user'
require_relative '../lib/nub/config'

class TestConfig < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
    Config.reset
  end

  def test_init
    assert_equal(Module, Config.init('foo.yml').class)
    assert_equal("/home/#{User.name}/.config/foo.yml", Config.path)
  end

  def test_config_sidecar_config
    path = File.expand_path(File.join(File.dirname(__FILE__), 'foobar.yml'))
    File.stub(:exists?, true) {
      Sys.capture{assert_raises(SystemExit){Config.init('foobar.yml')}}
      assert_equal(path, Config.path)
      assert_equal({}, Config.yml)
    }
  end

  def test_init_reload
    Config.init('foo.yml')
    Config['general'] = "bob"
    assert_equal("bob", Config['general'])
    Config.reset
    refute_equal("bob", Config['general'])
  end

  def test_init_no_reload
    Config.init('foo.yml')
    Config['general'] = "bob"
    assert_equal("bob", Config['general'])
    Config.init('foo.yml')
    assert_equal("bob", Config['general'])
  end

  def test_exists?
    assert(!Config.exists?)

    File.stub(:exists?, true) {
      assert(Config.exists?)
    }
  end

  def test_hash_get
    Config.yml = {'general' => 'foo'}
    assert_equal('foo', Config['general'])
  end

  def test_hash_set
    assert_nil(Config['general'])
    Config['general'] = 'foo'
    assert_equal('foo', Config['general'])
  end

  def test_config_get_success
    Config['general'] = 'foo'
    assert_equal('foo', Config.get!('general'))
  end

  def test_config_get_exit
    capture = Sys.capture{assert_raises(SystemExit){ Config.get!('foo') }}
    assert_equal("Error: couldn't find 'foo' in config!\n", capture.stdout.strip_color)
  end

  def test_save_fail
    Config.yml = nil
    assert_nil(Config.save)
  end

  def test_save_success
    data = {'general' => 'foo'}
    Config['general'] = 'foo'
    assert_equal('foo', Config['general'])
    assert_equal(data, Config.yml)

    mock = Minitest::Mock.new
    mock.expect(:write, true, ["---\ngeneral: foo\n"])
    File.stub(:open, true, mock){
      Config.save 
    }
    assert_mock(mock)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
