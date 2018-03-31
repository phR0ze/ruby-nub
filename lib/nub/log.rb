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

  # Get timestamp and location of call
  def call_details
    @@_monitor.synchronize{

      # Skip first 3 on stack (i.e. 0 = block in call_details, 1 = synchronize, 2 = call_detail) 
      stack = caller_locations(3, 10)

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
      regexps = [Regexp.new('^rescue\s.*in\s'), Regexp.new('^block\s.*in\s'), Regexp.new('^each$')]
      while regexps.any?{|regexp| stack[i].label =~ regexp} do
        break if i + 1 == stack.size
        i += 1
      end

      # Set label, clean up for block case
      label = stack[i].label
      regexps.each{|x| label = label.gsub(label[x], "") if stack[i].label =~ x}
      label = stack[i].label if label.empty?

      # Construct stamp
      location = ":#{File.basename(stack[i].path, '.rb')}:#{label}:#{lineno}"
      return Time.now.utc.iso8601(3), location
    }
  end

  def print(*args)
    @@_monitor.synchronize{
      str = !args.first.is_a?(Hash) ? args.first.to_s : ''

      # Format message
      opts = args.find{|x| x.is_a?(Hash)}
      loc = (opts && opts.key?(:loc)) ? opts[:loc] : false
      type = (opts && opts.key?(:type)) ? opts[:type] : ""
      stamp = (opts && opts.key?(:stamp)) ? opts[:stamp] : true
      if stamp or loc
        timestamp, location = call_details
        location = loc ? location : ""
        type = ":#{type}" if !type.empty?
        str = "#{timestamp}#{location}#{type}:: #{str}"
      end

      # Handle output
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

      # Format message
      opts = args.find{|x| x.is_a?(Hash)}
      loc = (opts && opts.key?(:loc)) ? opts[:loc] : false
      type = (opts && opts.key?(:type)) ? opts[:type] : ""
      stamp = (opts && opts.key?(:stamp)) ? opts[:stamp] : true

      str = str.colorize(:red) if type == 'E'
      str = str.colorize(:light_yellow) if type == 'W'

      if stamp or loc
        timestamp, location = call_details
        location = loc ? location : ""
        type = ":#{type}" if !type.empty?
        str = "#{timestamp}#{location}#{type}:: #{str}"
      end

      # Handle output
      @file.puts(Sys.strip_colorize(str)) if @path
      @@_queue << "#{str}\n" if @@_queue
      $stdout.puts(str) if @@_stdout

      return true
    }
  end

  def error(*args)
    opts = args.find{|x| x.is_a?(Hash)}
    opts[:loc] = true and opts[:type] = 'E' if opts
    args << {:loc => true, :type => 'E'} if !opts

    return puts(*args)
  end

  def warn(*args)
    if LogLevel.warn <= @@_level
      opts = args.find{|x| x.is_a?(Hash)}
      opts[:type] = 'W' if opts
      args << {:type => 'W'} if !opts
      return puts(*args)
    end
    return true
  end

  def info(*args)
    if LogLevel.info <= @@_level
      opts = args.find{|x| x.is_a?(Hash)}
      opts[:type] = 'I' if opts
      args << {:type => 'I'} if !opts
      return puts(*args)
    end
    return true
  end

  def debug(*args)
    if LogLevel.debug <= @@_level
      opts = args.find{|x| x.is_a?(Hash)}
      opts[:type] = 'D' if opts
      args << {:type => 'D'} if !opts
      return puts(*args)
    end
    return true
  end

  # Log the given message in red and exit
  # @param msg [String] message to log
  def die(msg)
    puts(msg.colorize(:red), stamp: false) and exit
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
