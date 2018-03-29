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
  # @param allowed [Array] array of allowed string values
  def initialize(key, desc, type:nil, required:false, allowed:[])
    @hint = nil
    @long = nil
    @short = nil
    @desc = desc
    @allowed = allowed || []
    @required = required || false

    # Parse the key into its components (short hand, long hand, and hint)
    #https://bneijt.nl/pr/ruby-regular-expressions/
    # Valid forms to look for with chars [a-zA-Z0-9-_=|] 
    # --help, --help=HINT, -h|--help, -h|--help=HINT
    !puts("Error: invalid option key #{key}".colorize(:red)) and
      exit if key && (key.count('=') > 1 or key.count('|') > 1 or !key[/[^\w\-=|]/].nil? or
        key[/(^--[a-zA-Z0-9\-_]+$)|(^--[a-zA-Z\-_]+=\w+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+=\w+$)/].nil?)
    @key = key
    if key
      @hint = key[/.*=(.*)$/, 1]
      @short = key[/^(-\w).*$/, 1]
      @long = key[/(--[\w\-]+)(=\w+)*$/, 1]
    else
      # Always require positional options
      @required = true
    end

    # Validate and set type
    !puts("Error: invalid option type #{type}".colorize(:red)) and
      exit if ![String, Integer, Array, nil].any?{|x| type == x}
    !puts("Error: option type must be set".colorize(:red)) and
      exit if @hint && !type
    @type = String if !key && !type
    @type = FalseClass if key and !type
    @type = type if type

    # Validate allowed
    if @allowed.any?
      allowed_type = @allowed.first.class
      !puts("Error: mixed allowed types".colorize(:red)) and
        exit if @allowed.any?{|x| x.class != allowed_type}
    end
  end
end

# An implementation of git like command syntax for ruby applications:
# see https://github.com/phR0ze/ruby-nub
class Commander
  attr_accessor(:cmds)
  attr_reader(:config)
  attr_reader(:banner)

  Command = Struct.new(:name, :desc, :opts, :help)

  # Initialize the commands for your application
  # @param app [String] application name e.g. reduce
  # @param version [String] version of the application e.g. 1.0.0
  # @param examples [String] optional examples to list after the title before usage
  def initialize(app, version, examples:nil)
    @app = app
    @version = version
    @examples = examples
    !puts("Error: app name and version are required".colorize(:red)) and
      exit if @app.nil? or @app.empty? or @version.nil? or @version.empty?

    @help_opt = Option.new('-h|--help', 'Print command/options help')
    @just = 40

    # Configuration - ordered list of commands
    @config = []

    # Incoming user set commands/options
    # {command_name => {}}
    @cmds = {}
  end

  # Hash like accessor for checking if a command or option is set
  def [](key)
    return @cmds[key] if @cmds[key]
  end

  # Add a command to the command list
  # @param cmd [String] name of the command
  # @param desc [String] description of the command
  # @param opts [List] list of command options
  def add(cmd, desc, options:[])
    !puts("Error: command names must be pure lowercase letters".colorize(:red)) and
      exit if cmd =~ /[^a-z]/

    # Build help for command
    help = "#{banner}\n#{desc}\n\nUsage: ./#{@app} #{cmd} [options]\n"
    options << @help_opt

    # Add positional options first
    sorted_options = options.select{|x| x.key.nil?}
    sorted_options += options.select{|x| !x.key.nil?}.sort{|x,y| x.key <=> y.key}
    positional_index = -1
    sorted_options.each{|x| 
      required = x.required ? ", Required" : ""
      allowed = x.allowed.empty? ? "" : " (#{x.allowed * ','})"
      positional_index += 1 if x.key.nil?
      key = x.key.nil? ? "#{cmd}#{positional_index}" : x.key
      type = x.type == FalseClass ? "Flag" : x.type
      help += "    #{key.ljust(@just)}#{x.desc}#{allowed}: #{type}#{required}\n"
    }

    # Create the command in the command config
    @config << Command.new(cmd, desc, sorted_options, help)
  end

  # Returns banner string
  # @returns [String] the app's banner
  def banner
    banner = "#{@app}_v#{@version}\n#{'-' * 80}".colorize(:light_yellow)
    return banner
  end

  # Return the app's help string
  # @returns [String] the app's help string
  def help
    help = "#{banner}\n"
    help += "Examples:\n#{@examples}\n\n" if !@examples.nil? && !@examples.empty?
    help += "Usage: ./#{@app} [commands] [options]\n"
    help += "    #{'-h|--help'.ljust(@just)}Print command/options help: Flag\n"
    help += "COMMANDS:\n"
    @config.each{|x| help += "    #{x.name.ljust(@just)}#{x.desc}\n" }
    help += "\nsee './#{@app} COMMAND --help' for specific command help\n"

    return help
  end

  # Construct the command line parser and parse
  def parse!

    # Set help if nothing was given
    ARGV.clear and ARGV << '-h' if ARGV.empty?

    # Process global options
    #---------------------------------------------------------------------------
    cmd_names = @config.map{|x| x.name }
    globals = ARGV.take_while{|x| !cmd_names.include?(x)}
    !puts(help) and exit if globals.any?
    
    # Process command options
    #---------------------------------------------------------------------------
    loop {
      break if ARGV.first.nil?

      # Process command
      if !(cmd = @config.find{|x| x.name == ARGV.first}).nil?

        # Set command and remove from possible command names
        @cmds[ARGV.shift.to_sym] = {}
        cmd_names.reject!{|x| x == cmd.name}

        # Collect command options
        opts = ARGV.take_while{|x| !cmd_names.include?(x) }
        ARGV.shift(opts.size)
        cmd_pos_opts = cmd.opts.select{|x| x.key.nil? }
        cmd_named_opts = cmd.opts.select{|x| !x.key.nil? }
        !puts("Error: positional option required".colorize(:red)) && !puts(cmd.help) and
          exit if opts.size < cmd_pos_opts.size

        # Process command options
        pos = -1
        loop {
          break if opts.first.nil?
          opt = opts.shift
          cmd_opt = nil
          value = nil
          sym = nil

          # Validate/set named options
          # e.g. -s, --skip, --skip=VALUE
          if opt.start_with?('-')
            short = opt[/^(-\w).*$/, 1]
            long = opt[/(--\w+)(=\w+)*$/, 1]
            value = opt[/.*=(.*)$/, 1]

            # Set symbol converting dashes to underscores for named options
            if (cmd_opt = cmd_named_opts.find{|x| x.short == short || x.long == long})
              sym = cmd_opt.long[2..-1].gsub("-", "_").to_sym
            else
              !puts("Error: unknown named option '#{opt}' given".colorize(:red)) && !puts(cmd.help) and exit
            end

            # Collect value
            if cmd_opt.type == FalseClass
              value = true if !value
            elsif !value
              value = opts.shift
            end

          # Validate/set positional options
          else
            pos += 1
            cmd_opt = cmd_pos_opts.shift
            !puts("Error: invalid positional option '#{opt}'".colorize(:red)) && !puts(cmd.help) and
              exit if cmd_opt.nil?
            value = opt
            sym = "#{cmd.name}#{pos}".to_sym
          end

          # Convert value to appropriate type
          if value
            if cmd_opt.type == Integer
              value = value.to_i

              # Validate allowed values
              if cmd_opt.allowed.any?
                !puts("Error: invalid integer value '#{value}'".colorize(:red)) && !puts(cmd.help) and
                  exit if !cmd_opt.allowed.include?(value)
              end

            elsif cmd_opt.type == Array
              value = value.split(',')

              # Validate allowed values
              if cmd_opt.allowed.any?
                value.each{|x|
                  !puts("Error: invalid array value '#{x}'".colorize(:red)) && !puts(cmd.help) and
                    exit if !cmd_opt.allowed.include?(x)
                }
              end
            end
          end

          # Set option with value
          @cmds[cmd.name.to_sym][sym] = value
        }
      end
    }

    # Ensure all options were consumed
    !puts("Error: invalid options #{ARGV}".colorize(:red)) and exit if ARGV.any?
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
