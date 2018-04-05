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

require 'time'
require 'colorize'
require 'minitest/autorun'
require_relative '../lib/nub/log'
require_relative '../lib/nub/sys'

class TestLog < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: false)
  end

  def test_each_inside_thread
    Log.init(path:nil, queue: true, stdout: false)
    Thread.new{
      ['foo'].each{|x| Log.info(x) }
    }    
    msg = Log.pop
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(!msg.include?(":test_each_inside_thread:"))
    assert(msg.end_with?("I:: foo\n"))
  end

  def test_rescue_inside_thread
    Log.init(path:nil, queue: true, stdout: false)
    Thread.new{
      begin
        raise
      rescue Exception => e
        Log.error("foobar")
      end
    }    
    msg = Log.pop
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(msg.include?(":test_rescue_inside_thread:"))
    assert(msg.end_with?("E:: #{'foobar'.colorize(:red)}\n"))
  end

  def test_multiaccess
    mock = Minitest::Mock.new
    mock.expect(:sync=, nil, [true])
    mock.expect(:sync=, nil, [true])

    File.stub(:exist?, true){
      File.stub(:open, mock){
        Log.init(path: 'foo.bar', queue:false, stdout:false)
        id = Log.id
        Log.init(path: 'foo.bar', queue:false, stdout:false)
        assert_equal(id, Log.id)
      }
    }

    assert_mock(mock)
  end

  def test_no_location_is_not_given_by_default
    Log.init(path:nil, queue: true, stdout: false)
    Log.puts("foo")
    msg = Log.pop
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(!msg.include?(":test_no_location_is_not_given_by_default:"))
    assert(msg.end_with?(":: foo\n"))
  end

  def test_no_location_is_given_by_default
    Log.init(path:nil, queue: true, stdout: false)
    Log.info("foo")
    msg = Log.pop
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(!msg.include?(":test_no_location_is_given_by_default:"))
    assert(msg.end_with?("I:: foo\n"))
  end

  def test_call_details
    stamp, loc = Log.call_details
    assert(stamp.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(loc.include?(":test_log:test_call_details:"))
  end

  def test_log_parent_of_each_with_index
    Log.init(path:nil, queue: true, stdout: false)
    ['foo','bar'].each{|x|
      Log.warn(x)
    }
    ["foo", "bar"].each_with_index{|x, i|
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(!msg.include?(":test_log_parent_of_each_with_index:"))
      assert(msg.end_with?("W:: #{x.colorize(:light_yellow)}\n"))
    }
  end

  def test_log_parent_of_each
    Log.init(path:nil, queue: true, stdout: false)
    ['foo','bar'].each{|x|
      Log.debug(x)
    }
    ["foo\n", "bar\n"].each{|x|
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(!msg.include?(":test_log_parent_of_each:"))
      assert(msg.end_with?(x))
      assert(msg.end_with?("D:: #{x}"))
    }
  end

  def test_log_parent_of_rescue
    Log.init(path:nil, queue: true, stdout: false)
    begin
      raise('raise exception')
    rescue
      Log.error("foo.bar")
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(msg.include?(":test_log_parent_of_rescue:"))
      assert(msg.end_with?("E:: #{'foo.bar'.colorize(:red)}\n"))
    end
  end

  def test_log_parent_of_block_not_block

    # format
    ['1', '2'].each{|x|
      stamp, loc = Log.call_details
      assert(stamp.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(loc.include?(":test_log:test_log_parent_of_block_not_block:"))
    }

    # print
    Log.init(path:nil, queue: true, stdout: false)
    ['1', '2'].each{|x|
      Log.print("foo.bar")
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(!msg.include?(":test_log_parent_of_block_not_block:"))
      assert(msg.end_with?(":: foo.bar"))
    }

    # puts
    ['1', '2'].each{|x|
      Log.puts("foo.bar")
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(!msg.include?(":test_log_parent_of_block_not_block:"))
      assert(msg.end_with?(":: foo.bar\n"))
    }

    # debug
    ['1', '2'].each{|x|
      Log.debug("foo.bar")
      msg = Log.pop
      assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
      assert(!msg.include?(":test_log_parent_of_block_not_block:"))
      assert(msg.end_with?("D:: foo.bar\n"))
    }
  end

  def test_file_puts_print
    mock = Minitest::Mock.new
    mock.expect(:sync=, nil, [true])
    mock.expect(:puts, nil, ["foobar"])
    mock.expect(:<<, nil, ["foobar"])

    File.stub(:exist?, false){
      FileUtils.stub(:mkdir_p, true){
        File.stub(:open, mock){
          Log.init(path: '/foo/bar', queue:false, stdout:false)
          Log.puts("foobar".colorize(:cyan), stamp:false)
          Log.print("foobar".colorize(:blue), stamp:false)
        }
      }
    }

    assert_mock(mock)
  end

  def test_stdout_print
    Log.init(path:nil, queue: false, stdout: true)
    capture = Sys.capture{ Log.print("foobar", stamp:false) }
    assert_equal("foobar", capture.stdout)
  end

  def test_stdout_puts
    Log.init(path:nil, queue: false, stdout: true)
    capture = Sys.capture{ Log.puts("foobar", stamp:false) }
    assert_equal("foobar\n", capture.stdout)
  end

  def test_stamp_print
    Log.init(path:nil, queue: true, stdout: false)
    Log.print("foobar", stamp:false)
    assert_equal("foobar", Log.pop)
    Log.print("foobar")
    assert("foobar" != Log.pop)
  end

  def test_stamp_puts
    Log.init(path:nil, queue: true, stdout: false)
    Log.puts("foobar", stamp:false)
    assert_equal("foobar\n", Log.pop)
    Log.puts("foobar")
    assert("foobar\n" != Log.pop)
  end

  def test_die
    assert_raises(SystemExit){
      Log.die("This is a test")
      assert(Log.pop.include?("This is a test"))
    }
  end

  def test_error
    Log.init(path:nil, queue: true, stdout: false)
    Log.error("error")
    assert(!Log.empty?)
    Log.pop
    assert(Log.empty?)
  end

  def test_warn
    Log.init(path:nil, queue: true, stdout: false)
    Log.warn("warning")
    assert(!Log.empty?)
    Log.pop
    assert(Log.empty?)
  end

  def test_warn_dropped
    Log.init(path:nil, level:LogLevel.error, queue: true, stdout: false)
    Log.warn("warning")
    assert(Log.empty?)
  end

  def test_info
    Log.init(path:nil, queue: true, stdout: false)
    Log.info("info")
    assert(!Log.empty?)
    assert(Log.pop.end_with?("I:: info\n"))
    assert(Log.empty?)
  end

  def test_info_dropped
    Log.init(path:nil, level:LogLevel.warn, queue: true, stdout: false)
    Log.info("info")
    assert(Log.empty?)
  end

  def test_debug
    Log.init(path:nil, queue: true, stdout: false)
    Log.debug("debug")
    assert(!Log.empty?)
    assert(Log.pop.end_with?("D:: debug\n"))
    assert(Log.empty?)
  end

  def test_logs_are_drooped_when_level_not_met
    Log.init(path:nil, level:LogLevel.info, queue: true, stdout: false)
    Log.info("info")
    assert(!Log.empty?)
    assert(Log.pop.include?("info"))
    assert(Log.empty?)

    Log.error("error")
    assert(!Log.empty?)
    assert(Log.pop.include?("error"))
    assert(Log.empty?)

    Log.debug("debug")
    assert(Log.empty?)
  end

  def test_open_log_file
    mock = Minitest::Mock.new
    mock.expect(:sync=, nil, [true])

    File.stub(:exist?, false){
      FileUtils.stub(:mkdir_p, true){
        File.stub(:open, mock){
          Log.init(path: '/foodir/foolog', queue:false, stdout:false)
        }
      }
    }

    assert_mock(mock)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
