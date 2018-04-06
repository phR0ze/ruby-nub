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
require_relative '../lib/nub/string'
require_relative '../lib/nub/commander'

class TestCommander < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
    ARGV.clear
  end

  def test_global_set
    ARGV.clear and ARGV << '-d'
    cmdr = Commander.new
    cmdr.add_global(Option.new('-d|--debug', 'Debug'))
    cmdr.parse!
  end

  def test_global_is_reserved_command
    cmdr = Commander.new
    capture = Sys.capture{ assert_raises(SystemExit){
      cmdr.add('global', 'global is reserved')
    }}
    assert_equal("Error: 'global' is a reserved command name!\n", capture.stdout.strip_color)
  end

  def test_global_named_help_with_banner
    expected =<<EOF
test_v0.0.1
--------------------------------------------------------------------------------
Usage: ./test [commands] [options]
Global options:
    -d|--debug                              Debug: Flag
    -h|--help                               Print command/options help: Flag
COMMANDS:

see './test COMMAND --help' for specific command help
EOF
    ARGV.clear and ARGV << '-h'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add_global(Option.new('-d|--debug', 'Debug'))
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout.strip_color)
  end

  def test_global_named_help_no_banner
    expected =<<EOF
Usage: ./test_commander.rb [commands] [options]
Global options:
    -d|--debug                              Debug: Flag
    -h|--help                               Print command/options help: Flag
COMMANDS:

see './test_commander.rb COMMAND --help' for specific command help
EOF
    cmdr = Commander.new
    cmdr.add_global(Option.new('-d|--debug', 'Debug'))
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_global_positional_not_allowed
    cmdr = Commander.new
    capture = Sys.capture{ assert_raises(SystemExit){
      cmdr.add_global(Option.new(nil, ''))
    }}
    assert_equal("Error: only named global options are allowed!\n", capture.stdout.strip_color)
  end

  def test_required_named_option_missing
    expected =<<EOF
Error: required option -c|--comp not given!
Build components

Usage: ./test_commander.rb build [options]
    -c|--comp                               Component to build: Flag, Required
    -h|--help                               Print command/options help: Flag
EOF
    ARGV.clear and ARGV << 'build'
    cmdr = Commander.new
    cmdr.add('build', 'Build components', options:[
      Option.new('-c|--comp', 'Component to build', required:true)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout.strip_color)
  end

  def test_chained_named
    ARGV.clear and ARGV << 'build' << 'publish' << '--comp'
    cmdr = Commander.new
    cmdr.add('build', 'Build components', options:[
      Option.new('-c|--comp', 'Component to build', required:true)
    ])
    cmdr.add('publish', 'Publish components', options:[
      Option.new('-c|--comp', 'Component to publish', required:true)
    ])
    cmdr.parse!
    assert(cmdr[:build][:comp])
    assert(cmdr[:publish][:comp])
  end

  def test_chained_named_inconsistent_types
expected =<<EOF
Error: chained command options are not type consistent!
Build components

Usage: ./test_commander.rb build [options]
    -c|--comp                               Component to build: Flag, Required
    -h|--help                               Print command/options help: Flag
EOF

    ARGV.clear and ARGV << 'build' << 'publish' << '--comp'
    cmdr = Commander.new
    cmdr.add('build', 'Build components', options:[
      Option.new('-c|--comp', 'Component to build', required:true)
    ])
    cmdr.add('publish', 'Publish components', options:[
      Option.new('-c|--comp', 'Component to publish', required:true, type:String)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout.strip_color)
  end

  def test_chained_positional_inconsistent_numbers
expected =<<EOF
Error: chained commands must have equal numbers of required options!
Build components

Usage: ./test_commander.rb build [options]
    build0                                  Component to build: String, Required
    -h|--help                               Print command/options help: Flag
EOF

    ARGV.clear and ARGV << 'build' << 'publish' << 'debug'
    cmdr = Commander.new
    cmdr.add('build', 'Build components', options:[
      Option.new(nil, 'Component to build')
    ])
    cmdr.add('publish', 'Publish components', options:[
      Option.new(nil, 'Component to publish'),
      Option.new(nil, 'Extra positional')
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout.strip_color)
  end

  def test_chained_positional
    ARGV.clear and ARGV << 'build' << 'publish' << 'deploy' << 'debug'
    cmdr = Commander.new
    cmdr.add('build', 'Build components', options:[Option.new(nil, 'Component to build')])
    cmdr.add('publish', 'Publish components', options:[Option.new(nil, 'Component to publish')])
    cmdr.add('deploy', 'Deploy components', options:[Option.new(nil, 'Component to deply')])
    cmdr.parse!
    assert_equal("debug", cmdr[:build][:build0])
    assert_equal("debug", cmdr[:publish][:publish0])
    assert_equal("debug", cmdr[:deploy][:deploy0])
  end

  def test_multi_positional_and_named_options
    ARGV.clear and ARGV << 'delete' << 'deployment' << 'tron' << '-n' << 'trondom'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('delete', 'Delete the given component', options:[
      Option.new(nil, 'Component type'),
      Option.new(nil, 'Component name'),
      Option.new('-n|--namespace=NAMESPACE', 'Namespace to use', type:String),
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal('deployment', cmdr[:delete][:delete0])
    assert_equal('tron', cmdr[:delete][:delete1])
    assert_equal('trondom', cmdr[:delete][:namespace])
  end

  def test_named_option_long_quotes_equal
    ARGV.clear and ARGV << 'bar' << '--foobar=foo foo'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', type:String),
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal('foo foo', cmdr[:bar][:foobar])
  end

  def test_named_option_long_array_equal
    ARGV.clear and ARGV << 'bar' << '--foobar' << 'foo1,foo2,foo3'
    cmdr = Commander.new
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo1', 'foo2', 'foo3'], type:Array),
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(['foo1', 'foo2', 'foo3'], cmdr[:bar][:foobar])
  end

  def test_named_option_long_array_equal
    ARGV.clear and ARGV << 'bar' << '--foobar=foo1,foo2,foo3'
    cmdr = Commander.new
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo1', 'foo2', 'foo3'], type:Array),
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(['foo1', 'foo2', 'foo3'], cmdr[:bar][:foobar])
  end

  def test_named_option_short_array
    ARGV.clear and ARGV << 'bar' << '-f' << 'foo1,foo2,foo3'
    cmdr = Commander.new
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo1', 'foo2', 'foo3'], type:Array),
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(['foo1', 'foo2', 'foo3'], cmdr[:bar][:foobar])
  end

  def test_named_option_long_string_equal
    ARGV.clear and ARGV << 'bar' << '--foobar=foo'
    cmdr = Commander.new
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo'], type:String),
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal("foo", cmdr[:bar][:foobar])
  end

  def test_named_option_long_string
    ARGV.clear and ARGV << 'bar' << '--foobar' << 'foo'
    cmdr = Commander.new
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo'], type:String),
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal("foo", cmdr[:bar][:foobar])
  end

  def test_named_option_short_string
    ARGV.clear and ARGV << 'bar' << '-f' << 'foo'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('bar', 'bar it up', options:[
      Option.new('-f|--foobar=FOOBAR', 'Set foo', allowed:['foo'], type:String),
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal("foo", cmdr[:bar][:foobar])
  end

  def test_named_option_long_int_equal
    ARGV.clear and ARGV << 'clean' << '--min=3'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal(3, cmdr[:clean][:min])
  end

  def test_named_option_long_int
    ARGV.clear and ARGV << 'clean' << '--min' << '3'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(3, cmdr[:clean][:min])
    assert_nil(cmdr[:clean][:debug])
    assert_nil(cmdr[:clean][:skip])
    assert_nil(cmdr[:clean][:clean0])
  end

  def test_named_option_short_invalid_int
    ARGV.clear and ARGV << 'clean' << '-m' << '4'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: invalid integer value '4'"))
    assert(capture.stdout.include?("Set the minimum"))
  end

  def test_named_option_short_int
    ARGV.clear and ARGV << 'clean' << '-m' << '1'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(1, cmdr[:clean][:min])
    assert_nil(cmdr[:clean][:debug])
    assert_nil(cmdr[:clean][:skip])
    assert_nil(cmdr[:clean][:clean0])
  end

  def test_named_option_long_flag
    ARGV.clear and ARGV << 'clean' << '--debug'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('clean', 'Clean components', options:[
      Option.new('-d|--debug', 'Debug mode'),
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal(true, cmdr[:clean][:debug])
  end

  def test_named_option_short_flag
    ARGV.clear and ARGV << 'clean' << '-d'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    assert(Sys.capture{ cmdr.parse! }.stdout.empty?)
    assert_equal(true, cmdr[:clean][:debug])
    assert_nil(cmdr[:clean][:min])
    assert_nil(cmdr[:clean][:skip])
    assert_nil(cmdr[:clean][:clean0])
  end

  def test_update_option
    ARGV.clear and ARGV << 'clean' << '3'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:[1, 3], type:Integer)
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal(3, cmdr[:clean][:clean0])
    cmdr[:clean][:clean0] = 2
    assert_equal(2, cmdr[:clean][:clean0])
  end

  def test_positional_integer_good
    ARGV.clear and ARGV << 'clean' << '3'
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:[1, 3], type:Integer)
    ])
    out = Sys.capture{ cmdr.parse! }.stdout.split("\n").map{|x| x.strip_color}
    assert(out.size == 2 && out.include?("test_v0.0.1"))
    assert_equal(3, cmdr[:clean][:clean0])
  end

  def test_positional_invalid_integer_value
    ARGV.clear and ARGV << 'clean' << '2'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:[1, 3], type:Integer)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: invalid integer value '2'"))
    assert(capture.stdout.include?("clean0"))
  end

  def test_positional_array_good
    ARGV.clear and ARGV << 'clean' << 'all'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array)
    ])
    out = Sys.capture{ cmdr.parse! }
    assert_equal("", out.stdout) # no output for succcess without app name
    assert_equal(["all"], cmdr[:clean][:clean0])
  end

  def test_positional_invalid_array_value
    ARGV.clear and ARGV << 'clean' << 'foo'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'], type:Array)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: invalid array value 'foo'"))
    assert(capture.stdout.include?("clean0"))
  end

  def test_positional_invalid_string_value
    ARGV.clear and ARGV << 'clean' << 'foo'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso'])
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: invalid string value 'foo'"))
    assert(capture.stdout.include?("clean0"))
  end

  def test_positional_option_too_many
    ARGV.clear and ARGV << 'clean' << 'foo' << 'bar'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components')
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: invalid positional option"))
    assert(capture.stdout.include?("clean0"))
  end

  def test_command_name_with_non_lowercase_letters_should_fail
    cmdr = Commander.new
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.add('clean-er', nil)}}
    assert(capture.stdout.include?("Error: command names must be pure lowercase letters"))
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.add('CLEAN', nil)}}
    assert(capture.stdout.include?("Error: command names must be pure lowercase letters"))
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.add('clean1', nil)}}
    assert(capture.stdout.include?("Error: command names must be pure lowercase letters"))
  end

  def test_positional_option_not_given
    ARGV.clear and ARGV << 'clean'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components')
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert(capture.stdout.include?("Error: positional option required"))
    assert(capture.stdout.include?("clean0"))
  end

  def test_command_help_long
    expected =<<EOF
Clean components

Usage: ./test_commander.rb clean [options]
    clean0                                  Clean given components (all,iso,image,boot): Array, Required
    -d|--debug                              Debug mode: Flag
    -h|--help                               Print command/options help: Flag
    -m|--min=MINIMUM                        Set the minimum clean (1,2,3): Integer
    -s|--skip=COMPONENTS                    Skip the given components (iso,image): Array
EOF
    ARGV.clear and ARGV << 'clean' << '--help'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image', 'boot'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_command_help_short
    expected =<<EOF
Clean components

Usage: ./test_commander.rb clean [options]
    clean0                                  Clean given components (all,iso,image,boot): Array, Required
    -d|--debug                              Debug mode: Flag
    -h|--help                               Print command/options help: Flag
    -m|--min=MINIMUM                        Set the minimum clean (1,2,3): Integer
    -s|--skip=COMPONENTS                    Skip the given components (iso,image): Array
EOF
    ARGV.clear and ARGV << 'clean' << '-h'
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image', 'boot'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_command_help_manual
    expected =<<EOF
Clean components

Usage: ./test_commander.rb clean [options]
    clean0                                  Clean given components (all,iso,image,boot): Array, Required
    -d|--debug                              Debug mode: Flag
    -h|--help                               Print command/options help: Flag
    -m|--min=MINIMUM                        Set the minimum clean (1,2,3): Integer
    -s|--skip=COMPONENTS                    Skip the given components (iso,image): Array
EOF
    cmdr = Commander.new
    cmdr.add('clean', 'Clean components', options:[
      Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image', 'boot'], type:Array),
      Option.new('-d|--debug', 'Debug mode'),
      Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
      Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
    ])
    assert_equal(expected, cmdr.config.find{|x| x.name == "clean"}.help)
  end

  def test_help_with_neither_app_nor_version
    expected =<<EOF
Usage: ./test_commander.rb [commands] [options]
Global options:
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test_commander.rb COMMAND --help' for specific command help
EOF
    cmdr = Commander.new
    cmdr.add('list', 'List command')

    # Test raw
    assert_equal(expected, cmdr.help)

    # Test invoked help
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_help_with_only_app_version
    expected =<<EOF
Usage: ./test_commander.rb [commands] [options]
Global options:
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test_commander.rb COMMAND --help' for specific command help
EOF
    cmdr = Commander.new(version:'0.0.1')
    cmdr.add('list', 'List command')

    # Test raw
    assert_equal(expected, cmdr.help)

    # Test invoked help
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_help_with_only_app_name
    expected =<<EOF
Usage: ./test [commands] [options]
Global options:
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test COMMAND --help' for specific command help
EOF
    cmdr = Commander.new(app:'test')
    cmdr.add('list', 'List command')

    # Test raw
    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.help)

    # Test invoked help
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_help_without_examples
    expected =<<EOF
Usage: ./test [commands] [options]
Global options:
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test COMMAND --help' for specific command help
EOF
    cmdr = Commander.new(app:'test', version:'0.0.1')
    cmdr.add('list', 'List command')

    # Test raw
    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.help)

    # Test invoked help
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_help_with_examples
    expected =<<EOF
Examples:
List: ./test list

Usage: ./test [commands] [options]
Global options:
    -h|--help                               Print command/options help: Flag
COMMANDS:
    list                                    List command

see './test COMMAND --help' for specific command help
EOF
    cmdr = Commander.new(app:'test', version:'0.0.1', examples:"List: ./test list")
    cmdr.add('list', 'List command')

    # Test raw help
    expected = "#{cmdr.banner}\n#{expected}"
    assert_equal(expected, cmdr.help)

    # Test invoked help
    capture = Sys.capture{ assert_raises(SystemExit){ cmdr.parse! } }
    assert_equal(expected, capture.stdout)
  end

  def test_help_is_reserved_option
    cmdr = Commander.new
    capture = Sys.capture{ assert_raises(SystemExit){
      cmdr.add('test', 'help is reserved', options:[
        Option.new('-h|--help', 'help is reserved')
      ])
    }}
    assert_equal("Error: 'help' is a reserved option name!\n", capture.stdout.strip_color)
  end

  def test_mixed_types_in_allow_should_fail
    capture = Sys.capture{ assert_raises(SystemExit){
      Option.new(nil, nil, allowed:[1, 'foo'])
    }}
    assert_equal("Error: mixed allowed types!\n", capture.stdout.strip_color)
  end

  def test_option_allowed
    assert_empty(Option.new(nil, nil).allowed)
    assert_equal(['foo', 'bar'], Option.new(nil, nil, allowed:['foo', 'bar']).allowed)
  end

  def test_option_required
    # Always require positional options
    assert(Option.new(nil, nil).required)

    # Named options may be optional
    assert(!Option.new("-h|--help", nil).required)
    assert(Option.new("-h|--help", nil, required:true).required)
  end

  def test_type_not_set_for_named_consuming_option
    capture = Sys.capture{ assert_raises(SystemExit){ Option.new("-f|--file=HINT", "desc")}}
    assert_equal("Error: option type must be set!\n", capture.stdout.strip_color)
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
      assert_raises(SystemExit){Option.new("-s", nil)}
    }

    # long only
    opt = Option.new("--skip", nil)
    assert_nil(opt.hint)
    assert_equal("--skip", opt.key)
    assert_equal("--skip", opt.long)
    assert_nil(opt.short)

    # long only with dash
    opt = Option.new("--skip-foo", nil)
    assert_nil(opt.hint)
    assert_equal("--skip-foo", opt.key)
    assert_equal("--skip-foo", opt.long)
    assert_nil(opt.short)

    # long, hint
    opt = Option.new("--skip=HINT", nil, type:String)
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
    opt = Option.new("-s|--skip=HINT", nil, type:String)
    assert_equal("HINT", opt.hint)
    assert_equal("-s|--skip=HINT", opt.key)
    assert_equal("-s", opt.short)
    assert_equal("--skip", opt.long)
  end

end

# vim: ft=ruby:ts=2:sw=2:sts=2
