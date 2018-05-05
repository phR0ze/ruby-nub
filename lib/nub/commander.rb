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
require 'pry'
require 'colorize'
require 'ostruct'
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

    # Convert true/false to TrueClass/FalseClass
    type = TrueClass if type.class == TrueClass
    type = FalseClass if type.class == FalseClass

    # Validate and set type, allow Flag defaults to be true or false
    Log.die("invalid option type #{type}") if ![String, Integer, Array, TrueClass, FalseClass, nil].any?{|x| type == x}
    Log.die("option type must be set") if @hint && !type
    @type = String if !key && !type
    @type = FalseClass if key and !type
    @type = type if type

    # Validate hint is given for non flags
    Log.die("option hint must be set") if @key && !@hint && @type != FalseClass && @type != TrueClass

    # Validate allowed
    if @allowed.any?
      allowed_type = @allowed.first.class
      Log.die("mixed allowed types") if @allowed.any?{|x| x.class != allowed_type}
    end
  end

  # Get a symbol representing the command
  # @returns symbol
  def to_sym
    return @long[2..-1].gsub("-", "_").to_sym
  end

  # Return a human readable string of this object
  # @param level [Integer] level to indent
  def to_s(level:0)
    return "#{" " * level * 2}Option => key:#{@key}, desc:'#{@desc}', type:#{@type}, allowed:#{@allowed}, required:#{@required}"
  end
end

class Command
  attr_reader(:name)
  attr_reader(:desc)
  attr_accessor(:nodes)
  attr_accessor(:help)

  # Create a new command
  # @param name [String] command name used on command line
  # @param desc [String] the command's description
  # @param nodes [String] the command's description
  def initialize(name, desc, nodes:[])
    @name = name
    @desc = desc
    @nodes = nodes
    @help = ""
  end

  # Get a symbol representing the command
  # @returns symbol
  def to_sym
    return @name.gsub('-', '_').to_sym
  end

  # Return a human readable string of this object
  # @param level [Integer] level to indent
  def to_s(level:0)
    str = "#{" " * level * 2}Command => name:#{@name}, desc:'#{@desc}'"
    @nodes.each{|x|
      str += "\n#{x.to_s(level: level + 1)}"
    }
    return str
  end
end

# An implementation of git like command syntax for ruby applications:
# see https://github.com/phR0ze/ruby-nub
class Commander
  attr_reader(:config)
  attr_reader(:banner)
  attr_accessor(:cmds)

  # Initialize the commands for your application
  # @param app [String] application name e.g. reduce
  # @param version [String] version of the application e.g. 1.0.0
  # @param examples [String] optional examples to list after the title before usage
  def initialize(app:nil, version:nil, examples:nil)
    @k = OpenStruct.new({
      global: 'global'
    })

    @app = app
    @app_default = Sys.caller_filename
    @version = version
    @examples = examples
    @just = 40

    # Regexps
    @short_regex = /^(-\w).*$/
    @long_regex = /(--[\w\-]+)(=.+)*$/
    @value_regex = /.*=(.*)$/

    # Command line expression results
    # {command_name => {}}
    @cmds = {}

    # Configuration - ordered list of commands
    @config = []

    # Configure default global options
    add_global('-h|--help', 'Print command/options help')
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
    Log.die("'#{@k.global}' is a reserved command name") if cmd == @k.global
    Log.die("'#{cmd}' already exists") if @config.any?{|x| x.name == cmd}
    Log.die("'help' is a reserved option name") if nodes.any?{|x| x.class == Option && !x.key.nil? && x.key.include?('help')}
    Log.die("command names must be pure lowercase letters or hypen") if cmd =~ /[^a-z-]/

    # Validate sub command key words
    validate_subcmd = ->(subcmd){
      subcmd.nodes = [] if !subcmd.nodes
      Log.die("'#{@k.global}' is a reserved command name") if subcmd.name == @k.global
      Log.die("'help' is a reserved option name") if subcmd.nodes.any?{|x| x.class == Option && !x.key.nil? && x.key.include?('help')}
      Log.die("command names must be pure lowercase letters or hypen") if subcmd.name =~ /[^a-z-]/
      subcmd.nodes.select{|x| x.class != Option}.each{|x| validate_subcmd.(x)}
    }
    nodes.select{|x| x.class != Option}.each{|x| validate_subcmd.(x)}

    @config << add_cmd(cmd, desc, nodes)
  end

  # Add global options (any option coming before all commands)
  # @param key [String] option short hand, long hand and hint e.g. -s|--skip=COMPONENTS
  # @param desc [String] the option's description
  # @param type [Type] the option's type
  # @param required [Bool] require the option if true else optional
  # @param allowed [Array] array of allowed string values
  def add_global(key, desc, type:nil, required:false, allowed:[])
    options = [Option.new(key, desc, type:type, required:required, allowed:allowed)]

    # Aggregate global options
    if (global = @config.find{|x| x.name == @k.global})
      global.nodes.each{|x| options << x}
      @config.reject!{|x| x.name == @k.global}
    end
    @config << add_cmd(@k.global, 'Global options:', options)
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

    # Global help
    help = @app.nil? ? "" : "#{banner}\n"
    if !@examples.nil? && !@examples.empty?
      newline = @examples.strip_color[-1] != "\n" ? "\n" : ""
      help += "Examples:\n#{@examples}\n#{newline}"
    end
    app = @app || @app_default
    help += "Usage: ./#{app} [commands] [options]\n"
    help += @config.find{|x| x.name == @k.global}.help
    help += "COMMANDS:\n"
    @config.select{|x| x.name != @k.global}.each{|x| help += "    #{x.name.ljust(@just)}#{x.desc}\n" }
    help += "\nsee './#{app} COMMAND --help' for specific command help\n"

    return help
  end

  # Construct the command line parser and parse
  def parse!

    # Clear out the previous run every time, in case run more than once
    @cmds = {}

    # Set help if nothing was given
    ARGV.clear and ARGV << '-h' if ARGV.empty?

    # Parse commands recursively
    move_globals_to_front!
    expand_chained_options!
    while (cmd = @config.find{|x| x.name == ARGV.first})
      ARGV.shift && parse_commands(cmd, nil, @config.select{|x| x.name != cmd.name}, ARGV, @cmds)
    end

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
      return opt.type == FalseClass || opt.type == TrueClass
    end
  end

  # Parse the given args recursively
  # @param cmd [Command] command to work with
  # @param parent [Command] command to work with
  # @param others [Array] sibling cmds to cmd
  # @param args [Array] array of arguments
  # @param results [Hash] of cmd results
  def parse_commands(cmd, parent, others, args, results)
    results[cmd.to_sym] = {}                            # Create command results entry
    cmd_names = others.map{|x| x.name}                  # Get other command names as markers
    subcmds = cmd.nodes.select{|x| x.class == Command}  # Get sub-commands for this command

    # Collect all params until the next sibling command
    #---------------------------------------------------------------------------
    params = args.take_while{|x| !cmd_names.include?(x)}
    args.shift(params.size)

    # Strip off this command's preceeding options
    opts = subcmds.any? ? params.take_while{|x| !subcmds.any?{|y| x == y.name}} : params
    otherparams = params[opts.size..-1]

    #---------------------------------------------------------------------------
    # Handle sub-commands recursively first
    #---------------------------------------------------------------------------
    while subcmds.any? && (subcmd = subcmds.find{|x| x.name == otherparams.first})
      otherparams.shift                             # Consume sub-cmd from opts
      subcmds.reject!{|x| x.name == subcmd.name}    # Drop sub-command from further use
      parse_commands(subcmd, cmd, subcmds, otherparams, results[cmd.to_sym])
    end

    # Account for any left over options
    otherparams.reverse.each{|x| opts.unshift(x)}

    #---------------------------------------------------------------------------
    # Base case: dealing with options for a given command.
    # Only consume options for this command and bubble up unused to parent
    #---------------------------------------------------------------------------

    # Handle help upfront before anything else
    #---------------------------------------------------------------------------
    if opts.any?{|x| m = match_named(x, cmd); m.hit? && m.sym == :help }
      !puts(help) and exit if cmd.name == @k.global
      !puts(cmd.help) and exit
    end

    # Parse/consume named options first
    #---------------------------------------------------------------------------

    # Check that all required named options were given
    cmd.nodes.select{|x| x.class == Option && !x.key.nil? && x.required}.each{|x|
      !puts("Error: required option #{x.key} not given!".colorize(:red)) && !puts(cmd.help) and
        exit if !match_named(x, opts).hit?
    }

    # Consume and set all named options
    i = 0 
    while i < opts.size
      if (match = match_named(opts[i], cmd)).hit?
        value = match.flag? || match.value  # Inline or Flag value

        # Separate value
        separate = false
        if !value && i + 1 < opts.size
          separate = true
          value = opts[i + 1]
        elsif !value
          !puts("Error: named option '#{opts[i]}' value not found!".colorize(:red)) and
            !puts(cmd.help) and exit
        end

        # Set result and consume options
        results[cmd.to_sym][match.sym] = convert_value(value, cmd, match.opt)
        opts.delete_at(i)                   # Consume option
        opts.delete_at(i) if separate       # Consume separate value
      else
        i += 1
      end
    end

    # Parse/consume positional options next
    #---------------------------------------------------------------------------
    cmd_pos_opts = cmd.nodes.select{|x| x.class == Option && x.key.nil?}

    # Check that all required positionals were given
    !puts("Error: positional option required!".colorize(:red)) && !puts(cmd.help) and
      exit if opts.select{|x| !x.start_with?('-')}.size < cmd_pos_opts.select{|x| x.required}.size

    # Consume and set all positional options
    i = 0
    pos = -1
    while i < opts.size && cmd_pos_opts.any?
      if !opts[i].start_with?('-')
        pos += 1
        cmd_opt = cmd_pos_opts.shift
        !puts("Error: invalid positional option '#{opts[i]}'!".colorize(:red)) and 
          !puts(cmd.help) and exit if cmd_opt.nil?

        # Set result and consume options
        results[cmd.to_sym]["#{cmd.to_sym}#{pos}".to_sym] = convert_value(opts[i], cmd, cmd_opt)
        opts.delete_at(i)                   # Consume option
      else
        i += 1
      end
    end

    # Add any unconsumed options back to parent to ensure everything is accounted for
    if parent
      opts.reverse.each{|x| args.unshift(x)}
    else
      opts.each{|x|
        !puts("Error: invalid positional option '#{x}'!".colorize(:red)) and 
          !puts(cmd.help) and exit if !x.start_with?('-')
        !puts("Error: invalid named option '#{x}'!".colorize(:red)) and
          !puts(cmd.help) and exit if x.start_with?('-')
      }
    end
  end

  # Parses the command line, moving all global options to the begining
  # and inserting the global command
  def move_globals_to_front!
    if !(global_cmd = @config.find{|x| x.name == @k.global}).nil?
      ARGV.delete(@k.global)

      # Collect positional and named options from begining
      globals = ARGV.take_while{|x| !@config.any?{|y| y.name == x}}
      ARGV.shift(globals.size)

      # Collect named options throughout
      i = -1
      cmd = nil
      while (i += 1) < ARGV.size

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
      ARGV.unshift(@k.global)
    end
  end

  # Find chained options, copy and insert as needed.
  # Globals should have already been ordered before calling this function
  # Fail if validation doesn't pass
  def expand_chained_options!
    args = ARGV[0..-1]
    results = {}
    cmd_order = []
    cmd_names = @config.map{|x| x.name}

    chained = []
    while args.any?
      if !(cmd = @config.find{|x| x.name == args.first}).nil?
        cmd_order << args.shift                   # Maintain oder of given commands
        results[cmd.name] = []                    # Add the command to the results
        cmd_names.reject!{|x| x == cmd.name}      # Remove command from possible commands

        # Collect command options from args to compare against
        opts = args.take_while{|x| !cmd_names.include?(x)}
        args.shift(opts.size)

        # Globals are not to be considered for chaining
        results[cmd.name].concat(opts) and next if cmd.name == @k.global

        # Chained case is when no options are given but the command has options
        cmd_options = cmd.nodes.select{|x| x.class == Option}
        if opts.size == 0 && cmd_options.any?
          chained << cmd
        else
          # Add cmd with options
          results[cmd.name].concat(opts)

          # Add applicable options to chained as well
          chained.each{|other|
            _opts = opts[0..-1]
            named_results = []
            positional_results = []

            # Add all matching named options
            #-------------------------------------------------------------------
            i = 0 
            while i < _opts.size
              if (match = match_named(_opts[i], other)).hit?
                named_results << _opts[i];
                _opts.delete_at(i)

                # Get the next option to as the value was separate
                if i < _opts.size && !(match.flag? || match.value)
                  named_results << _opts[i]
                  _opts.delete_at(i)
                end
              else
                i += 1
              end
            end

            # Add all matching positional options
            #-------------------------------------------------------------------
            i = 0
            other_positional = other.nodes.select{|x| x.class == Option && x.key.nil?}
            while i < _opts.size
              if !_opts[i].start_with?('-') && other_positional.any?
                positional_results << _opts[i]
                other_positional.shift
                _opts.delete_at(i)
              else
                i += 1
              end
            end

            positional_results.each{|x| results[other.name] << x}
            named_results.each{|x| results[other.name] << x}
          }
        end
      end
    end

    # Set results as new ARGV command line expression
    ARGV.clear and cmd_order.each{|x| ARGV << x; ARGV.concat(results[x]) }
  end

  # Match the given command line arg with a configured named option
  # or match configured named option against a list of command line args
  # @param arg [String/Option] the command line argument or configured Option
  # @param other [Command/Array] configured command or command line args
  # @return [OptionMatch]] struct with some helper functions
  def match_named(arg, other)
    match = OptionMatch.new

    # Match command line arg against command options
    if arg.class == String && other.class == Command
      match.arg = arg
      options = other.nodes.select{|x| x.class == Option && !x.key.nil? }

      if arg.start_with?('-')
        short = arg[@short_regex, 1]
        long = arg[@long_regex, 1]
        match.value = arg[@value_regex, 1]

        # Set symbol converting dashes to underscores for named options
        if (match.opt = options.find{|x| x.short == short || x.long == long})
          match.sym = match.opt.to_sym
        end
      end

    # Match command option against command line args
    elsif arg.class == Option && other.class == Array
      match.arg = arg.key

      other.select{|x| x.start_with?('-')}.any?{|x|
        short = x[@short_regex, 1]
        long = x[@long_regex, 1]
        value = x[@value_regex, 1]
        if short == arg.short || long == arg.long
          match.opt = arg
          match.value = value
          match.sym = match.opt.to_sym
        end
      }
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
  # @param name [String] name of the command
  # @param desc [String] description of the command
  # @param nodes [Array] list of command nodes (i.e. options or commands)
  # @param hierarchy [Array] list of commands
  # @return [Command] new command
  def add_cmd(name, desc, nodes, hierarchy:[])
    hierarchy << name
    cmd = Command.new(name, desc)
    subcmds = nodes.select{|x| x.class == Command}.sort{|x,y| x.name <=> y.name}

    # Build help for command
    #---------------------------------------------------------------------------
    cmd.help = "#{desc}\n"
    app = @app || @app_default
    cmd_prompt = subcmds.any? ? "[commands] " : ""
    cmd.help += "\nUsage: ./#{app} #{hierarchy * ' '} #{cmd_prompt}[options]\n" if name != @k.global
    cmd.help = "#{banner}\n#{cmd.help}" if @app && name != @k.global

    # Add help for each sub-command before options
    cmd.help += "COMMANDS:\n" if subcmds.any?
    subcmds.each{|x| cmd.help += "    #{x.name.ljust(@just)}#{x.desc}\n" }

    # Insert standard help option for command (re-using one from global, all identical)
    nodes << @config.find{|x| x.name == @k.global}.nodes.find{|x| x.long == '--help'} if name != @k.global

    # Add positional options first
    sorted_options = nodes.select{|x| x.class == Option && x.key.nil?}
    sorted_options += nodes.select{|x| x.class == Option && !x.key.nil?}.sort{|x,y| x.key <=> y.key}
    cmd.help += "OPTIONS:\n" if subcmds.any? && sorted_options.any?
    positional_index = -1
    sorted_options.each{|x|
      required = x.required ? ", Required" : ""
      allowed = x.allowed.empty? ? "" : " (#{x.allowed * ','})"
      positional_index += 1 if x.key.nil?
      key = x.key.nil? ? "#{name}#{positional_index}" : x.key
      type = (x.type == FalseClass || x.type == TrueClass) ? "Flag(#{x.type.to_s[/(.*)Class/, 1].downcase})" : x.type
      cmd.help += "    #{key.ljust(@just)}#{x.desc}#{allowed}: #{type}#{required}\n"
    }

    # Add hint as to how to get specific sub command help
    cmd.help += "\nsee './#{app} #{name} COMMAND --help' for specific command help\n" if subcmds.any?

    # Configure help for each sub command
    subcmds.each{|x| cmd.nodes << add_cmd(x.name, x.desc, x.nodes, hierarchy:hierarchy)}

    # Add options after any sub-commands
    cmd.nodes += sorted_options

    return cmd
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
