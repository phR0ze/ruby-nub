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
require 'monitor'
require 'ostruct'
require 'colorize'

ColorPair = Struct.new(:str, :color)
ColorMap = {
  "30" => "black",
  "31" => "red",
  "32" => "green",
  "33" => "yellow",
  "34" => "blue",
  "35" => "magenta",
  "36" => "cyan",
  "37" => "white",
  "39" => "gray88"   # default
}

LogLevel = OpenStruct.new({
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
})

# Singleton logger for use with both console and gtk+ apps.
# Logs to both a file and the console/queue for shell/UI apps.
# Uses Mutex.synchronize where required to provide thread safety.
module Log
  extend self
  @@_level = 3
  @@_queue = nil
  @@_stdout = true
  @@_monitor = Monitor.new

  # Public properties
  class << self
    attr_reader(:id, :path)
  end

  # Singleton's init method can be called multiple times to reset.
  # @param path [String] path to log file
  # @param queue [Bool] use a queue as well
  # @param stdout [Bool] turn on or off stdout
  # @param level [LogLevel] level at which to log
  def init(path:nil, level:LogLevel.debug, queue:false, stdout:true)
    @id ||= 'singleton'.object_id

    @path = path ? File.expand_path(path) : nil
    @@_level = level
    @@_queue = queue ? Queue.new : nil
    @@_stdout = stdout

    # Open log file creating as needed
    if @path
      FileUtils.mkdir_p(File.dirname(@path)) if !File.exist?(File.dirname(@path))
      @file = File.open(@path, 'a')
      @file.sync = true
    end

    return nil
  end

  # Format the given string for use in log
  def format(str)
    @@_monitor.synchronize{

      # Locate caller
      stack = caller_locations(3,10)
      i = -1
      while i += 1 do
        mod = File.basename(stack[i].path, '.rb')
        break if !['log', 'monitor'].include?(mod)
      end

      # Save lineno from non log call but use method name rather than rescue or block
      lineno = stack[i].lineno
      nested = ['rescue in', 'block in', 'each']
      while nested.any?{|x| stack[i].label.include?(x)} do
        i += 1
      end
      loc = ":#{File.basename(stack[i].path, '.rb')}:#{stack[i].label}:#{lineno}"

      return "#{Time.now.utc.iso8601(3)}#{loc}:: #{str}"
    }
  end

  def print(*args)
    @@_monitor.synchronize{
      str = !args.first.is_a?(Hash) ? args.first.to_s : ''

      # Determine if stamp should be used
      stamp = true
      opts = args.find{|x| x.is_a?(Hash)}
      if opts and opts.key?(:stamp)
        stamp = opts[:stamp]
      end

      # Format message
      str = format(str) if stamp

      if !str.empty?
        @file << strip_colorize(str) if @path
        @@_queue << str if @@_queue
        $stdout.print(str) if @@_stdout
      end

      return true
    }
  end

  def puts(*args)
    @@_monitor.synchronize{
      str = !args.first.is_a?(Hash) ? args.first.to_s : ''

      # Determine if stamp should be used
      stamp = true
      opts = args.find{|x| x.is_a?(Hash)}
      if opts and opts.key?(:stamp)
        stamp = opts[:stamp]
      end

      # Format message
      str = format(str) if stamp

      # Handle output
      @file.puts(strip_colorize(str)) if @path
      @@_queue << "#{str}\n" if @@_queue
      $stdout.puts(str) if @@_stdout

      return true
    }
  end

  def error(*args)
    return puts(*args) if LogLevel.error <= @@_level
    return true
  end

  def warn(*args)
    return puts(*args) if LogLevel.warn <= @@_level
    return true
  end

  def info(*args)
    return puts(*args) if LogLevel.info <= @@_level
    return true
  end

  def debug(*args)
    return puts(*args) if LogLevel.debug <= @@_level
    return true
  end

  # Log the given message in red and exit
  # @param msg [String] message to log
  def die(msg)
    puts(msg.colorize(:red)) and exit
  end

  # Remove an item from the queue, block until one exists
  def pop()
    return @@_queue ? @@_queue.pop : nil
  end

  # Check if the log queue is empty
  def empty?
    return @@_queue ? @@_queue.empty? : true
  end

  # Strip the ansi color codes from the given string
  # @param str [String] string with ansi color codes
  # @returns [String] string without any ansi codes
  def strip_colorize(str)
    @@_monitor.synchronize{
      return str.gsub(/\e\[0;[39]\d;49m/, '').gsub(/\e\[0m/, '')
    }
  end

  # Tokenize the given colorized string
  # @param str [String] string with ansi color codes
  # @returns [Array] array of Token
  def tokenize_colorize(str)
    @@_monitor.synchronize{
      tokens = []
      matches = str.to_enum(:scan, /\e\[0;[39]\d;49m(.*?[\s]*)\e\[0m/).map{Regexp.last_match}

      i, istart, iend = 0, 0, 0
      match = matches[i]
      while istart < str.size
        color = "39"
        iend = str.size
        token = str[istart..iend]

        # Current token is not a match
        if match && match.begin(0) != istart
          iend = match.begin(0)-1
          token = str[istart..iend]
          istart = iend + 1

        # Current token is a match
        elsif match && match.begin(0) == istart
          iend = match.end(0)
          token = match.captures.first
          color = match.to_s[/\e\[0;(\d+);49m.*/, 1]
          i += 1; match = matches[i]
          istart = iend

        # Ending
        else
          istart = iend
        end

        # Create token and advance
        tokens << ColorPair.new(token, color)
      end

      return tokens
    }
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
