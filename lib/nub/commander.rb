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

require 'colorize'

# Command option encapsulation
class Option
  attr_reader(:key)
  attr_reader(:short)
  attr_reader(:long)
  attr_reader(:hint)
  attr_reader(:desc)
  attr_reader(:type)
  attr_reader(:allowed)
  attr_reader(:required)

  # Create a new option instance
  # @param key [String] option short hand, long hand and hint e.g. -s|--skip=COMPONENTS
  # @param desc [String] the option's description
  # @param type [Type] the option's type
  # @param required [Bool] require the option if true else optional
  # @param allowed []
  def initialize(key, desc, type:nil, required:false, allowed:nil)
    @hint = nil
    @long = nil
    @short = nil
    @desc = desc
    @allowed = allowed
    @required = required

    # Parse the key into its components (short hand, long hand, and hint)
    # Valid forms to look for
    # -h, --help, --help=HINT, -h|--help, -h|--help=HINT
    !puts("Error: invalid option key #{key}".colorize(:red)) and
      exit if key && (key.count('=') > 1 or key.count('|') > 1 or
        key[/(^-[a-zA-Z]$)|(^--[a-zA-Z0-9\-_]+$)|(^--[a-zA-Z\-_]+=\w+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+=\w+$)/].nil?)
    @key = key
    if key
      @hint = key[/.*=(.*)$/, 1]
      @short = key[/^(-\w).*$/, 1]
      @long = key[/(--\w+)(=\w+)*$/, 1]
    else
      # Always require positional options
      @required = true
    end

    # Validate and set type
    !puts("Error: invalid option type #{type}".colorize(:red)) and
      exit if ![String, Integer, Array, nil].any?{|x| type == x}
    @type = String if !key && !type
    @type = FalseClass if key and !type
    @type = type if type
  end

  # Parse the given command line parameters
  # @param key [String] option key
  # @param val [String] option val
  # @returns the value if there is a match
  def parse(key, val)
    value = nil

    # Positional option
    if !@key && !val
      value = params.first

    # Named option flag
    elsif params.size == 1 && [@short, @long].any?{|x| x == params.first}
      value = true

    # Named option short with value
    elsif params.size == 2 && params.first == @short
      value = params.
    elsif params.size == 2 && params.first == @short
    end

    # Convert value to appropriate type
    if value
      if @type == Integer
        value = value.to_i
      elsif @type == Array
        value = value.split(',')
      end
    end
  
    return value
  end
end

# An implementation of git like command syntax for ruby applications:
# see https://github.com/phR0ze/ruby-nub
class Commander
  attr_accessor(:cmds)
  Command = Struct.new(:name, :desc, :opts)

  # Initialize the commands for your application
  # @param app [String] application name e.g. reduce
  # @param version [String] version of the application e.g. 1.0.0
  # @param examples [String] optional examples to list after the title before usage
  def initialize(app, version, examples)
    @app = app
    @version = version
    @examples = examples || ''

    # Configuration for the command parser
    # {command_name => {}}
    @config = {}

    # Incoming user set commands/options
    # {command_name => {}}
    @cmds = {}
  end

  # Hash like accessor for checking if a command or option is set
  def [](key)
    return @cmds[key] if @cmds[key]
  end

  # Hash like accessor for editing options
  def []=(key, value)
    @opts[key] = value
  end

  # Add a command to the command list
  # @param cmd [String] name of the command
  # @param desc [String] description of the command
  # @param opts [List] list of command options
  def add(cmd, desc, opts)
    @config[cmd] = {
      desc: desc,
      opts: opts,
      banner: "#{banner}\nUsage: "
    }
  end

  # Returns banner string
  def banner
    banner = "#{@app}_v#{@version}\n#{'-' * 80}".colorize(:light_yellow)
    return banner
  end

  # Construct the command line parser and parse
  def parse!

    # Construct help for the application
    help = "COMMANDS:\n"
    @config.each{|k,v| help += "    #{k.ljust(33, ' ')}#{v[:desc]}\n" }
    help += "\nsee './#{@app} COMMAND --help' for specific command help"

    # Construct top level option parser
#    @optparser = OptionParser.new do |parser|
#      parser.banner = "#{banner}\n#{@examples}Usage: ./#{@app} commands [options]"
#      parser.on('-h', '--help', 'Print command/options help') {|x| !puts(parser) and exit }
#      parser.separator(help)
#    end

    # Invoke help if any un-recognized commands are given
    cmds = ARGV.select{|x| not x.start_with?('-')}
    ARGV.clear and ARGV << '-h' if ARGV.empty? or cmds.any?{|x| not @config[x]}
    cmds.each{|x| puts("Error: Invalid command '#{x}'".colorize(:red)) if not @config[x]}
    @optparser.order!

#    # Now remove them from ARGV leaving only options
#    ARGV.reject!{|x| not x.start_with?('-')}
#
#    # Parse each command which will consume options from ARGV
#    cmds.each do |cmd|
#      begin
#        @cmds[cmd.gsub('-', '_').to_sym] = true
#        @config[cmd][:outopts].order!
#
#        # Ensure that all required options were given
#        @config[cmd][:inopts].each{|x|
#          if x.required and not @opts[x.key]
#            puts("Error: Missing required option '#{x.key}'".colorize(:red))
#            ARGV.clear and ARGV << "-h"
#            @config[cmd][:outopts].order!
#          end
#        }
#      rescue OptionParser::InvalidOption => e
#        # Options parser will raise an invalid exception if it doesn't recognize something
#        # However we want to ignore that as it may be another command's option
#        ARGV << e.to_s[/(-.*)/, 1]
#      end
#    end

    # Ensure all options were consumed
    !puts("Error: invalid options #{ARGV}".colorize(:red)) and exit if ARGV.any?
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
