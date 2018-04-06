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
require_relative 'log'
require_relative 'sys'
require_relative 'string'

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
  attr_accessor(:shared)

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
    @shared = false
    @allowed = allowed || []
    @required = required || false

    # Parse the key into its components (short hand, long hand, and hint)
    #https://bneijt.nl/pr/ruby-regular-expressions/
    # Valid forms to look for with chars [a-zA-Z0-9-_=|] 
    # --help, --help=HINT, -h|--help, -h|--help=HINT
    Log.die("invalid option key #{key}") if key && (key.count('=') > 1 or key.count('|') > 1 or !key[/[^\w\-=|]/].nil? or
      key[/(^--[a-zA-Z0-9\-_]+$)|(^--[a-zA-Z\-_]+=\w+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+=\w+$)/].nil?)
    @key = key
    if key
      @hint = key[/.*=(.*)$/, 1]
      @short = key[/^(-\w).*$/, 1]
      @long = key[/(--[\w\-]+)(=.+)*$/, 1]
    else
      # Always require positional options
      @required = true
    end

    # Validate and set type
    Log.die("invalid option type #{type}") if ![String, Integer, Array, nil].any?{|x| type == x}
    Log.die("option type must be set") if @hint && !type
    @type = String if !key && !type
    @type = FalseClass if key and !type
    @type = type if type

    # Validate allowed
    if @allowed.any?
      allowed_type = @allowed.first.class
      Log.die("mixed allowed types") if @allowed.any?{|x| x.class != allowed_type}
    end
  end
end

# An implementation of git like command syntax for ruby applications:
# see https://github.com/phR0ze/ruby-nub
class Commander
  attr_reader(:config)
  attr_reader(:banner)
  attr_accessor(:cmds)

  Command = Struct.new(:name, :desc, :opts, :help)

  # Initialize the commands for your application
  # @param app [String] application name e.g. reduce
  # @param version [String] version of the application e.g. 1.0.0
  # @param examples [String] optional examples to list after the title before usage
  def initialize(app:nil, version:nil, examples:nil)
    @app = app
    @app_default = Sys.caller_filename
    @version = version
    @examples = examples
    @just = 40

    # Regexps
    @short_regex = /^(-\w).*$/
    @long_regex = /(--[\w\-]+)(=.+)*$/
    @value_regex = /.*=(.*)$/

    # Incoming user set commands/options
    # {command_name => {}}
    @cmds = {}

    # Configuration - ordered list of commands
    @config = []

    # List of options that will be added to all commands
    @shared = []

    # Configure default global options
    add_global(Option.new('-h|--help', 'Print command/options help'))
  end

  # Hash like accessor for checking if a command or option is set
  def [](key)
    return @cmds[key] if @cmds[key]
  end

  # Test if the key exists
  def key?(key)
    return @cmds.key?(key)
  end

  # Add a command to the command list
  # @param cmd [String] name of the command
  # @param desc [String] description of the command
  # @param opts [List] list of command options
  def add(cmd, desc, options:[])
    Log.die("'global' is a reserved command name") if cmd == 'global'
    Log.die("'shared' is a reserved command name") if cmd == 'shared'
    Log.die("'#{cmd}' already exists") if @config.any?{|x| x.name == cmd}
    Log.die("'help' is a reserved option name") if options.any?{|x| !x.key.nil? && x.key.include?('help')}

    # Add shared options
    @shared.each{|x| options.unshift(x)}

    cmd = add_cmd(cmd, desc, options)
    @config << cmd
  end

  # Add global options (any option coming before all commands)
  # @param option/s [Array/Option] array or single option/s
  def add_global(options)
    options = [options] if options.class == Option
    Log.die("only named global options are allowed") if options.any?{|x| x.key.nil?}

    # Process the global options, removed the old ones and add new ones
    if (global = @config.find{|x| x.name == 'global'})
      global.opts.each{|x| options << x}
      @config.reject!{|x| x.name == 'global'}
    end
    @config << add_cmd('global', 'Global options:', options)
  end

  # Add shared option (options that are added to all commands)
  # @param option/s [Array/Option] array or single option/s
  def add_shared(options)
    options = [options] if options.class == Option
    options.each{|x|
      Log.die("duplicate shared option '#{x.desc}' given") if @shared
        .any?{|y| y.key == x.key && y.desc == x.desc && y.type == x.type}
      x.shared = true
      @shared << x
    }
  end

  # Returns banner string
  # @returns [String] the app's banner
  def banner
    version = @version.nil? ? "" : "_v#{@version}"
    banner = "#{@app}#{version}\n#{'-' * 80}".colorize(:light_yellow)
    return banner
  end

  # Return the app's help string
  # @returns [String] the app's help string
  def help
    help = @app.nil? ? "" : "#{banner}\n"
    if !@examples.nil? && !@examples.empty?
      newline = @examples.strip_color[-1] != "\n" ? "\n" : ""
      help += "Examples:\n#{@examples}\n#{newline}"
    end
    app = @app || @app_default
    help += "Usage: ./#{app} [commands] [options]\n"
    help += @config.find{|x| x.name == 'global'}.help
    help += "COMMANDS:\n"
    @config.select{|x| x.name != 'global'}.each{|x| help += "    #{x.name.ljust(@just)}#{x.desc}\n" }
    help += "\nsee './#{app} COMMAND --help' for specific command help\n"

    return help
  end

  # Construct the command line parser and parse
  def parse!

    # Set help if nothing was given
    ARGV.clear and ARGV << '-h' if ARGV.empty?

    # Process global options
    #---------------------------------------------------------------------------
    cmd_names = @config.map{|x| x.name }
    ARGV.unshift('global') if ARGV.take_while{|x| !cmd_names.include?(x)}.any?
    
    # Process command options
    #---------------------------------------------------------------------------
    loop {
      break if ARGV.first.nil?

      if !(cmd = @config.find{|x| x.name == ARGV.first}).nil?
        @cmds[ARGV.shift.to_sym] = {}
        cmd_names.reject!{|x| x == cmd.name}

        # Command options as defined in configuration
        cmd_pos_opts = cmd.opts.select{|x| x.key.nil? }
        cmd_named_opts = cmd.opts.select{|x| !x.key.nil? }

        # Collect command options from args to compare against
        opts = ARGV.take_while{|x| !cmd_names.include?(x) }
        ARGV.shift(opts.size)

        # All positional options are required. If they are not given then check for the 'chained
        # command expression' case for positional options in the next command that satisfy the
        # previous command's requirements and so on and so forth.
        if opts.size == 0 && (cmd_pos_opts.any? || cmd_named_opts.any?{|x| x.required})
          i = 0
          while (i += 1) < ARGV.size do
            opts = ARGV[i..-1].take_while{|x| !cmd_names.include?(x) }
            break if opts.any? 
          end

          # Check that the chained command options at least match types and size
          if opts.any?
            cmd_required = cmd.opts.select{|x| x.key.nil? || x.required}
            other = @config.find{|x| x.name == ARGV[i-1]}
            other_required = other.opts.select{|x| x.key.nil? || x.required}

            !puts("Error: chained commands must have equal numbers of required options!".colorize(:red)) && !puts(cmd.help) and
              exit if cmd_required.size != other_required.size
            cmd_required.each_with_index{|x,i|
              !puts("Error: chained command options are not type consistent!".colorize(:red)) && !puts(cmd.help) and
                exit if x.type != other_required[i].type || x.key != other_required[i].key
            }
          end
        end

        # Check that all positional options were given
        !puts("Error: positional option required!".colorize(:red)) && !puts(cmd.help) and
          exit if opts.size < cmd_pos_opts.size

        # Check that all required named options where given
        named_opts = opts.select{|x| x.start_with?('-')}
        cmd_named_opts.select{|x| x.required}.each{|x|
          !puts("Error: required option #{x.key} not given!".colorize(:red)) && !puts(cmd.help) and
            exit if !named_opts.find{|y| y.start_with?(x.short) || y.start_with?(x.long)}
        }

        # Process command options
        pos = -1
        loop {
          break if opts.first.nil?
          opt = opts.shift
          cmd_opt = nil
          value = nil
          sym = nil

          # Validate/set named options
          # --------------------------------------------------------------------
          # e.g. -s, --skip, --skip=VALUE
          if opt.start_with?('-')
            short = opt[@short_regex, 1]
            long = opt[@long_regex, 1]
            value = opt[@value_regex, 1]

            # Set symbol converting dashes to underscores for named options
            if (cmd_opt = cmd_named_opts.find{|x| x.short == short || x.long == long})
              sym = cmd_opt.long[2..-1].gsub("-", "_").to_sym

              # Handle help for the command
              !puts(help) and exit if cmd.name == 'global' && sym == :help
              !puts(cmd.help) and exit if sym == :help

              # Collect value
              if cmd_opt.type == FalseClass
                value = true if !value
              elsif !value
                value = opts.shift
              end
            end

          # Validate/set positional options
          # --------------------------------------------------------------------
          else
            pos += 1
            cmd_opt = cmd_pos_opts.shift
            !puts("Error: invalid positional option '#{opt}'!".colorize(:red)) && !puts(cmd.help) and
              !puts("START:#{ARGV}:END") and exit if cmd_opt.nil?
            value = opt
            sym = "#{cmd.name}#{pos}".to_sym
          end

          # Convert value to appropriate type and validate against allowed
          # --------------------------------------------------------------------
          if value
            if cmd_opt.type == String
              if cmd_opt.allowed.any?
                !puts("Error: invalid string value '#{value}'!".colorize(:red)) && !puts(cmd.help) and
                  exit if !cmd_opt.allowed.include?(value)
              end
            elsif cmd_opt.type == Integer
              value = value.to_i
              if cmd_opt.allowed.any?
                !puts("Error: invalid integer value '#{value}'!".colorize(:red)) && !puts(cmd.help) and
                  exit if !cmd_opt.allowed.include?(value)
              end
            elsif cmd_opt.type == Array
              value = value.split(',')
              if cmd_opt.allowed.any?
                value.each{|x|
                  !puts("Error: invalid array value '#{x}'!".colorize(:red)) && !puts(cmd.help) and
                    exit if !cmd_opt.allowed.include?(x)
                }
              end
            end
          end

          # Set option with value
          # --------------------------------------------------------------------
          !puts("Error: unknown named option '#{opt}' given!".colorize(:red)) && !puts(cmd.help) and exit if !sym
          @cmds[cmd.name.to_sym][sym] = value
          if cmd_opt.shared
            sym = "shared#{pos}".to_sym if cmd_opt.key.nil?
            @cmds[:shared] = {} if !@cmds.key?(:shared)
            @cmds[:shared][sym] = value
          end
        }
      end
    }

    # Ensure specials (global, shared) are always set
    @cmds[:global] = {} if !@cmds[:global]
    @cmds[:shared] = {} if !@cmds[:shared]

    # Ensure all options were consumed
    Log.die("invalid options #{ARGV}") if ARGV.any?

    # Print banner on success
    puts(banner) if @app
  end

  #-----------------------------------------------------------------------------
  # Private methods
  #-----------------------------------------------------------------------------
  private

  # Add a command to the command list
  # @param cmd [String] name of the command
  # @param desc [String] description of the command
  # @param opts [List] list of command options
  # @returns cmd [Command] new command
  def add_cmd(cmd, desc, options)
    Log.die("command names must be pure lowercase letters") if cmd =~ /[^a-z]/

    # Build help for command
    app = @app || @app_default
    help = "#{desc}\n"
    help += "\nUsage: ./#{app} #{cmd} [options]\n" if cmd != 'global'
    help = "#{banner}\n#{help}" if @app && cmd != 'global'

    # Add help option if not global command
    options << @config.find{|x| x.name == 'global'}.opts.find{|x| x.long == '--help'} if cmd != 'global'

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
    return Command.new(cmd, desc, sorted_options, help)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
