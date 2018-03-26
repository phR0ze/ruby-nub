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
require_relative '../lib/nub/commander'

class TestCommander < Minitest::Test

  def test_option_type
    # No type, positional option
    assert_equal(String, Option.new(nil, "").type) 
    
    # No type, named option
    assert_equal(FalseClass, Option.new("-h|--help", "").type) 

    # Valid types
    assert_equal(String, Option.new(nil, "", type:String).type) 
    assert_equal(Integer, Option.new(nil, "", type:Integer).type) 
    assert_equal(Array, Option.new(nil, "", type:Array).type) 

    # Invalid type
    $stdout.stub(:write, nil){
      assert_raises(SystemExit){Option.new(nil, "", type:Hash)}
    }
  end

  def test_option_desc
    assert_equal("foobar", Option.new(nil, "foobar").desc) 
  end

  def test_option_key

    # Error cases
    $stdout.stub(:write, nil){
      assert_raises(SystemExit){Option.new("-s=COMPONENTS", nil)}
      assert_raises(SystemExit){Option.new("-s|--skip=FOO=BAR", nil)}
      assert_raises(SystemExit){Option.new("-s|--skip|", nil)}
      assert_raises(SystemExit){Option.new("--skip=FOO=BAR", nil)}
      assert_raises(SystemExit){Option.new("-s, --skip=FOO", nil)}
      assert_raises(SystemExit){Option.new("--skip|-s", nil)}
      assert_raises(SystemExit){Option.new("--skip|", nil)}
      assert_raises(SystemExit){Option.new("-s|skip", nil)}
      assert_raises(SystemExit){Option.new("-s|=HINT", nil)}
    }

    # short only
    opt = Option.new("-s", nil)
    assert_nil(opt.hint)
    assert_equal("-s", opt.key)
    assert_equal("-s", opt.short)
    assert_nil(opt.long)

    # long only
    opt = Option.new("--skip", nil)
    assert_nil(opt.hint)
    assert_equal("--skip", opt.key)
    assert_equal("--skip", opt.long)
    assert_nil(opt.short)

    # long, hint
    opt = Option.new("--skip=HINT", nil)
    assert_equal("HINT", opt.hint)
    assert_equal("--skip", opt.long)
    assert_nil(opt.short)
    
    # short, long no hint
    opt = Option.new("-s|--skip", nil)
    assert_nil(opt.hint)
    assert_equal("-s|--skip", opt.key)
    assert_equal("-s", opt.short)
    assert_equal("--skip", opt.long)

    # short, long, hint
    opt = Option.new("-s|--skip=HINT", nil)
    assert_equal("HINT", opt.hint)
    assert_equal("-s|--skip=HINT", opt.key)
    assert_equal("-s", opt.short)
    assert_equal("--skip", opt.long)
  end

#  def test_command_with_opts
#    cmd = Command.new("foo", "Foo command")
#
#    assert_equal("foo", cmd.name)
#    assert_equal("Foo command", cmd.desc)
#    assert_empty(cmd.opts)
#  end

#  def test_command_no_opts
#    cmd = Command.new("foo", "Foo command")
#    assert_equal("foo", cmd.name)
#    assert_equal("Foo command", cmd.desc)
#    assert_empty(cmd.opts)
#  end

#  def test_app_help_nothing_given
#    cmdr = Commander.new('test', '0', nil)
#    cmdr.add('list', 'List command', [])
#    cmdr.parse!
#    #assert(cmdr[:list])
#  end

#  def test_single_command_no_options
#    ARGV.clear and ARGV << 'list'
#    cmdr = Commander.new('test', '0', nil)
#    cmdr.add('list', 'List command', [])
#    assert_nil(cmdr[:list])
#    cmdr.parse!
#    assert(cmdr[:list])
#  end
  
#  def test_single_command_position_option
#    ARGV.clear and ARGV << 'clean all'
#    cmdr = Commander.new('test', '0', nil)
#    cmdr.add('clean', 'Clean command', [
#      CmdOpt.new(nil, 'Clean given components [all|iso|image]')
#    ])
#    cmdr.parse!
#    assert(cmdr[:clean])
#    #assert(cmdr[:clean_pos0])
#  end

#  def test_hypens_to_underscores_in_command
#    ARGV.clear and ARGV << 'fix-links'
#    opts = Cmds.new('test', '0.1.2', "")
#    opts.add('fix-links', 'Test hypend commands', [
#      CmdOpt.new('--all', 'List all info'),
#    ])
#    opts.parse!
#    assert(opts[:fix_links])
#  end
#
#  def test_updating_options
#    ARGV.clear and ARGV << 'fix-links'
#    opts = Cmds.new('test', '0.1.2', "")
#    opts.add('fix-links', 'Test hypend commands', [
#      CmdOpt.new('--all', 'List all info'),
#    ])
#    opts.parse!
#    assert(!opts[:bob])
#    opts[:bob] = true
#    assert(opts[:bob])
#  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
