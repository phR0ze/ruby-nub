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

# Singleton logger for use with both console and gtk+ apps
# logs to both a file and the console/queue for shell/UI apps
# uses Mutex.synchronize where required to provide thread safty
module Log
  extend self

  # Private properties
  @@_queue = nil
  @@_monitor = Monitor.new

  # Public properties
  class << self
    attr_reader(:id, :path)
  end

  # Singleton new alternate initialize
  # Can be called multiple times to reset
  # @param path [String] path to log file
  # @param queue [Bool] use a queue as well
  # @param stdout [Bool] turn on or off stdout
  def init(path:nil, queue:false, stdout:true)
    @id ||= 'singleton'.object_id

    @@_queue = queue ? Queue.new : nil
    @path = path ? File.expand_path(path) : nil
    @queue = queue
    @stdout = stdout

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
      return "#{Time.now.utc.iso8601(3)}:: #{str}"
    }
  end

  def print(str, notime:false)
    @@_monitor.synchronize{
      str ||= ""
      str = format(str) if !notime

      if !str.empty?
        @file << strip_colorize(str) if @path
        @@_queue << str if @queue
        $stdout.print(str) if @stdout
      end

      return true
    }
  end

  def puts(str, notime: false)
    @@_monitor.synchronize{
      str ||= ""
      str = format(str) if !notime

      if !str.empty?
        @file << "#{strip_colorize(str)}\n" if @path
        @@_queue << "#{str}\n" if @queue
        $stdout << "#{str}\n" if @stdout
      end

      return true
    }
  end

  # Remove an item from the queue, block until one exists
  def pop()
    return @queue ? @@_queue.pop : nil
  end

  # Check if the log queue is empty
  def empty?
    return @queue ? @@_queue.empty? : true
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
