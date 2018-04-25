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
  attr_accessor(:allowed)
  attr_accessor(:required)

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
    Log.die("invalid option key #{key}") if key && (key.count('=') > 1 or key.count('|') > 1 or !key[/[^\w\-=|]/].nil? or
      key[/(^--[a-zA-Z0-9\-_]+$)|(^--[a-zA-Z\-_]+=\w+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+$)|(^-[a-zA-Z]\|--[a-zA-Z0-9\-_]+=\w+$)/].nil?)
    @key = key
    if key
      @hint = key[/.*=(.*)$/, 1]
      @short = key[/^(-\w).*$/, 1]
      @long = key[/(--[\w\-]+)(=.+)*$/, 1]
    end

    # Validate and set type
    Log.die("invalid option type #{type}") if ![String, Integer, Array, nil].any?{|x| type == x}
    Log.die("option type must be set") if @hint && !type
    @type = String if !key && !type
    @type = FalseClass if key and !type
    @type = type if type

    # Validate hint is given for non flags
    Log.die("option hint must be set") if @key && !@hint && @type != FalseClass

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

  Command = Struct.new(:name, :desc, :nodes, :help)

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
  # @param nodes [List] list of command nodes (i.e. options or commands)
  def add(cmd, desc, nodes:[])
    Log.die("'global' is a reserved command name") if cmd == 'global'
    Log.die("'#{cmd}' already exists") if @config.any?{|x| x.name == cmd}
    Log.die("'help' is a reserved option name") if nodes.any?{|x| x.class == Option && !x.key.nil? && x.key.include?('help')}

    # Validte sub commands
    validate_sub_cmd = ->(sub_cmd){
      Log.die("'global' is a reserved command name") if sub_cmd.name == 'global'
      Log.die("'help' is a reserved option name") if sub_cmd.nodes.any?{|x| x.class == Option && !x.key.nil? && x.key.include?('help')}
      sub_cmd.nodes.select{|x| x.class != Option}.each{|x| validate_sub_cmd.(x)}
    }
    nodes.select{|x| x.class != Option}.each{|x| validate_sub_cmd.(x)}

    @config << add_cmd(cmd, desc, nodes)
  end

  # Add global options (any option coming before all commands)
  # @param option/s [Array/Option] array or single option/s
  def add_global(options)
    options = [options] if options.class != Array
    Log.die("only options are allowed as globals") if options.any?{|x| x.class != Option}

    # Aggregate global options
    if (global = @config.find{|x| x.name == 'global'})
      global.nodes.each{|x| options << x}
      @config.reject!{|x| x.name == 'global'}
    end
    @config << add_cmd('global', 'Global options:', options)
  end

  # Returns banner string
  # @return [String] the app's banner
  def banner
    version = @version.nil? ? "" : "_v#{@version}"
    banner = "#{@app}#{version}\n#{'-' * 80}".colorize(:light_yellow)
    return banner
  end

  # Return the app's help string
  # @return [String] the app's help string
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
    cmd_names = @config.map{|x| x.name }

    # Set help if nothing was given
    ARGV.clear and ARGV << '-h' if ARGV.empty?

    # Process command options
    #---------------------------------------------------------------------------
    order_globals!
    expand_chained_options!
    loop {
      break if ARGV.first.nil?

      if !(cmd = @config.find{|x| x.name == ARGV.first}).nil?
        @cmds[ARGV.shift.to_sym] = {}             # Create command results entry
        cmd_names.reject!{|x| x == cmd.name}      # Remove command from possible commands

        # Collect command options from args to compare against
        opts = ARGV.take_while{|x| !cmd_names.include?(x) }
        ARGV.shift(opts.size)

        # Handle help upfront before anything else
        if opts.any?{|x| m = match_named(x, cmd); m.hit? && m.sym == :help }
          !puts(help) and exit if cmd.name == 'global'
          !puts(cmd.help) and exit
        end

        # Check that all required options were given
        cmd_pos_opts = cmd.nodes.select{|x| x.key.nil? }
        cmd_named_opts = cmd.nodes.select{|x| !x.key.nil? }

        !puts("Error: positional option required!".colorize(:red)) && !puts(cmd.help) and
          exit if opts.select{|x| !x.start_with?('-')}.size < cmd_pos_opts.select{|x| x.required}.size

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
          if (match = match_named(opt, cmd)).hit?
            sym = match.sym
            cmd_opt = match.opt
            value = match.value
            value = match.flag? || opts.shift if !value

          # Validate/set positional options
          # --------------------------------------------------------------------
          else
            pos += 1
            value = opt
            cmd_opt = cmd_pos_opts.shift
            !puts("Error: invalid positional option '#{opt}'!".colorize(:red)) && !puts(cmd.help) and
              exit if cmd_opt.nil? || cmd_names.include?(value)
            sym = "#{cmd.name}#{pos}".to_sym
          end

          # Convert value to appropriate type and validate against allowed
          # --------------------------------------------------------------------
          value = convert_value(value, cmd, cmd_opt)

          # Set option with value
          # --------------------------------------------------------------------
          !puts("Error: unknown named option '#{opt}' given!".colorize(:red)) && !puts(cmd.help) and exit if !sym
          @cmds[cmd.name.to_sym][sym] = value
        }
      end
    }

    # Ensure specials (global) are always set
    @cmds[:global] = {} if !@cmds[:global]

    # Ensure all options were consumed
    Log.die("invalid options #{ARGV}") if ARGV.any?

    # Print banner on success
    puts(banner) if @app
  end

  #-----------------------------------------------------------------------------
  # Private methods
  #-----------------------------------------------------------------------------
  private
  OptionMatch = Struct.new(:arg, :sym, :value, :opt) do
    def hit?
      return !!sym
    end
    def flag?
      return opt.type == FalseClass
    end
  end

  # Parses the command line, moving all global options to the begining
  # and inserting the global command
  def order_globals!
    if !(global_cmd = @config.find{|x| x.name == 'global'}).nil?
      ARGV.delete('global')

      # Collect positional and named options from begining
      globals = ARGV.take_while{|x| !@config.any?{|y| y.name == x}}
      ARGV.shift(globals.size)

      # Collect named options throughout
      i = -1
      cmd = nil
      while (i += 1) < ARGV.size do

        # Set command and skip command and matching options
        if !(_cmd = @config.find{|x| x.name == ARGV[i]}).nil?
          cmd = _cmd; next
        end
        next if cmd && match_named(ARGV[i], cmd).hit?

        # Collect global matches
        if (match = match_named(ARGV[i], global_cmd)).hit?
          globals << ARGV.delete_at(i)
          globals << ARGV.delete_at(i) if !match.flag?
          i -= 1
        end
      end

      # Re-insert options in correct order at end with command
      globals.reverse.each{|x| ARGV.unshift(x)}
      ARGV.unshift('global')
    end
  end

  # Find chained options, copy and insert as needed.
  # Globals should have already been ordered before calling this function
  # Fail if validation doesn't pass
  def expand_chained_options!
    args = ARGV[0..-1]
    results = {}
    cmd_names = @config.map{|x| x.name }

    chained = []
    while args.any? do
      if !(cmd = @config.find{|x| x.name == args.first}).nil?
        results[args.shift] = []                            # Add the command to the results
        cmd_names.reject!{|x| x == cmd.name}                # Remove command from possible commands
        cmd_required = cmd.nodes.select{|x| x.required}

        # Collect command options from args to compare against
        opts = args.take_while{|x| !cmd_names.include?(x)}
        args.shift(opts.size)

        # Globals are not to be considered for chaining
        results[cmd.name].concat(opts) and next if cmd.name == 'global'

        # Chained case is when no options are given but some are required
        if opts.size == 0 && cmd.nodes.any?{|x| x.required}
          chained << cmd
        else
          results[cmd.name].concat(opts)

          chained.each{|x|
            other_required = x.nodes.select{|x| x.required}
            !puts("Error: chained commands must have equal numbers of required options!".colorize(:red)) && !puts(x.help) and
              exit if cmd_required.size != other_required.size
            cmd_required.each_with_index{|y,i|
              !puts("Error: chained command options are not type consistent!".colorize(:red)) && !puts(x.help) and
                exit if y.type != other_required[i].type || y.key != other_required[i].key
            }
            results[x.name].concat(opts)
          }
        end
      end
    end

    # Set results as new ARGV command line expression
    ARGV.clear and results.each{|k, v| ARGV << k; ARGV.concat(v)}
  end

  # Match the given command line arg with a configured named option
  # @param opt [String] the command line argument given
  # @param cmd [Command] configured command to match against
  # @return [OptionMatch]] struct with some helper functions
  def match_named(opt, cmd)
    match = OptionMatch.new(opt)
    cmd_named_opts = cmd.nodes.select{|x| !x.key.nil? }

    if opt.start_with?('-')
      short = opt[@short_regex, 1]
      long = opt[@long_regex, 1]
      match.value = opt[@value_regex, 1]

      # Set symbol converting dashes to underscores for named options
      if (cmd_opt = cmd_named_opts.find{|x| x.short == short || x.long == long})
        match.opt = cmd_opt
        match.sym = cmd_opt.long[2..-1].gsub("-", "_").to_sym
      end
    end

    return match
  end

  # Convert the given option value to appropriate type and validate against allowed
  # @param value [String] type to convert and and check
  # @param cmd [Command] configured command to reference
  # @param opt [Option] matching option to validate against
  # @return [String|Integer|Array] depending on option type
  def convert_value(value, cmd, opt)
    if value
      if opt.type == String
        if opt.allowed.any?
          !puts("Error: invalid string value '#{value}'!".colorize(:red)) && !puts(cmd.help) and
            exit if !opt.allowed.include?(value)
        end
      elsif opt.type == Integer
        value = value.to_i
        if opt.allowed.any?
          !puts("Error: invalid integer value '#{value}'!".colorize(:red)) && !puts(cmd.help) and
            exit if !opt.allowed.include?(value)
        end
      elsif opt.type == Array
        value = value.split(',')
        if opt.allowed.any?
          value.each{|x|
            !puts("Error: invalid array value '#{x}'!".colorize(:red)) && !puts(cmd.help) and
              exit if !opt.allowed.include?(x)
          }
        end
      end
    end

    return value
  end

  # Add a command to the command list
  # @param cmd [String] name of the command
  # @param desc [String] description of the command
  # @param nodes [List] list of command nodes (i.e. options or commands)
  # @return [Command] new command
  def add_cmd(cmd, desc, nodes)
    Log.die("command names must be pure lowercase letters") if cmd =~ /[^a-z]/

    # Build help for command
    app = @app || @app_default
    help = "#{desc}\n"
    help += "\nUsage: ./#{app} #{cmd} [options]\n" if cmd != 'global'
    help = "#{banner}\n#{help}" if @app && cmd != 'global'

    # Add help option if not global command
    nodes << @config.find{|x| x.name == 'global'}.nodes.find{|x| x.long == '--help'} if cmd != 'global'

    # Add positional options first
    sorted_options = nodes.select{|x| x.key.nil?}
    sorted_options += nodes.select{|x| !x.key.nil?}.sort{|x,y| x.key <=> y.key}
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
