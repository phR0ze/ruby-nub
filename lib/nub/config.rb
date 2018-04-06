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

require 'yaml'
require 'colorize'

require_relative 'user'
require_relative 'log'

# Simple YAML configuration for an application.
# Uses singleton pattern for single source of truth
module Config
  extend self
  @@_yml = nil

  # Public properties
  class << self
    attr_accessor :path
  end

  # Singleton new alternate
  # @param config [String] name or path of the config file
  def init(config)

    # Determine caller's file path to look for sidecar config
    caller_path = caller_locations(1, 1).first.path
    @path = File.expand_path(File.join(File.dirname(caller_path), config))
    if !File.exists?(@path)
      @path = "/home/#{User.name}/.config/#{config.split('/').first}"
    end

    # Open the config file or create in memory yml
    begin
      @@_yml = File.exists?(@path) ? YAML.load_file(@path) : {}
    rescue Exception => e
      Log.die(e)
    end

    return nil
  end

  # Simple bool whether the config exists or not on disk
  def exists?
      return File.exists?(@path)
  end

  # Hash like getter
  def [](key)
    return @@_yml[key]
  end

  # Hash like setter
  def []=(key, val)
    return @@_yml[key] = val
  end

  # Get the given key and raise an error if it doesn't exist
  def get!(key)
    Log.die("couldn't find '#{key}' in config") if !@@_yml.key?(key)
    return @@_yml[key]
  end

  # Save the config file
  def save
    File.write(@path, @@_yml.to_yaml) if @@_yml
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
