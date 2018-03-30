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
require_relative 'sys'

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
  end

  # Format the given string for use in log
  def format(str)
    @@_monitor.synchronize{

      # Skip first 3 on stack (i.e. 0 = block in format, 1 = synchronize, 2 = format) 
      stack = caller_locations(3, 10)
      stack.each{|x| $stdout.puts(x.label)}

      # Skip past any calls in 'log.rb' or 'monitor.rb'
      i = -1
      while i += 1 do
        mod = File.basename(stack[i].path, '.rb')
        break if !['log', 'monitor'].include?(mod)
      end

      # Save lineno from original location
      lineno = stack[i].lineno

      # Skip over block type functions to use method.
      # Note: there may not be a non block method e.g. in thread case
      nested = ['rescue in ', 'block in ']
      while nested.any?{|x| stack[i].label.include?(x) || stack[i].label == "each"} do
        break if i + 1 == stack.size
        i += 1
      end

      # Set label, clean up for block case
      label = stack[i].label
      nested.each{|x| label = label.gsub(x, "") if stack[i].label.include?(x)}

      # Construct stamp
      loc = ":#{File.basename(stack[i].path, '.rb')}:#{label}:#{lineno}"
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
        @file << Sys.strip_colorize(str) if @path
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
      @file.puts(Sys.strip_colorize(str)) if @path
      @@_queue << "#{str}\n" if @@_queue
      $stdout.puts(str) if @@_stdout

      return true
    }
  end

  def error(*args)
    return puts(*args)
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
  def pop
    return @@_queue ? @@_queue.pop : nil
  end

  # Check if the log queue is empty
  def empty?
    return @@_queue ? @@_queue.empty? : true
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
