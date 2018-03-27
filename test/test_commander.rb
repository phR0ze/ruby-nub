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
require_relative '../lib/nub/sys'
require_relative '../lib/nub/commander'

class TestCommander < Minitest::Test

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

#  def test_single_command_no_options
#    ARGV.clear and ARGV << 'list'
#    cmdr = Commander.new('test', '0')
#    cmdr.add('list', 'List command', [])
#    assert_nil(cmdr[:list])
#    cmdr.parse!
#    assert(cmdr[:list])
#  end
  
#  def test_single_command_position_option
#    ARGV.clear and ARGV << 'clean all'
#    cmdr = Commander.new('test', '0')
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

  def test_help_no_params
    cmdr = Commander.new('test', '0.0.1')
    cmdr.add('list', 'List command')
    capture = Sys.capture{ cmdr.parse! }
    assert(!capture.stdout.empty?)
  end

  def test_command_help
    expected =<<EOF
Clean components

Usage: ./test clean [options]
    clean0                                  Clean given components (all,iso,image,boot): Array, Required
    -d|--debug                              Debug mode: Flag
    -h|--help                               Print command/options help: Flag
    -m|--min=MINIMUM                        Set the minimum clean (1,2,3): Integer
    -s|--skip=COMPONENTS                    Skip the given components (iso,image): Array
EOF
    cmdr = Commander.new('test', '0.0.1')
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image', 'boot'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.config.find{|x| x.name == "clean"}.help)
  end

  def test_help_without_examples
    expected =<<EOF
Usage: ./test [commands] [options]
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test COMMAND --help' for specific command help
EOF
    cmdr = Commander.new('test', '0.0.1')
    cmdr.add('list', 'List command')

    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.help)
  end

  def test_help_with_examples
    expected =<<EOF
Examples:
List: ./test list

Usage: ./test [commands] [options]
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test COMMAND --help' for specific command help
EOF
    cmdr = Commander.new('test', '0.0.1', examples:"List: ./test list")
    cmdr.add('list', 'List command')

    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.help)
  end

#  def test_option_parse
#    # Named Flag short
#    opt = Option.new('-s', nil)
#    assert_equal(true, opt.parse(['-s']))
#
#    # Named Flag long
#    opt = Option.new('--skip', nil)
#    assert_equal(true, opt.parse(['--skip']))
#
#    # Positional String
#    opt = Option.new(nil, nil)
#    assert_equal("foo", opt.parse(['foo']))
#
#    # Positional Integer
#    opt = Option.new(nil, nil, type:Integer)
#    assert_equal(4, opt.parse(['4']))
#
#    # Positional Array
#    opt = Option.new(nil, nil, type:Array)
#    assert_equal(['foo', 'bar'], opt.parse(['foo,bar']))
#  end

  def test_option_allowed
    assert_nil(Option.new(nil, nil).allowed)
    assert_equal(['foo', 'bar'], Option.new(nil, nil, allowed:['foo', 'bar']).allowed)
  end

  def test_option_required
    # Always require positional options
    assert(Option.new(nil, nil).required)

    # Named options may be optional
    assert(!Option.new("-h", nil).required)
    assert(Option.new("-h", nil, required:true).required)
  end

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

end

# vim: ft=ruby:ts=2:sw=2:sts=2
