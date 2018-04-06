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

require 'io/console'
require 'ostruct'
require 'stringio'
require_relative 'log'

module Sys
  extend self

  # Get the given environment variable by nam
  # @param var [String] name of the environment var
  # @param required [Bool] require that the variable exists by default
  def env(var, required:true)
    value = ENV[var]
    Log.die("#{var} env variable is required!") if required && !value
    return value
  end

  # Wait for any key to be pressed  
  def any_key?
    begin
      state = `stty -g`
      `stty raw -echo -icanon isig`
      STDIN.getc.chr
    ensure
      `stty #{state}`
    end
  end

  # Get the caller's filename for the caller of the function this call is nested in
  # not the function this call is called in
  # @returns [String] the caller's filename
  def caller_filename
    path = caller_locations(2, 1).first.path
    return File.basename(path)
  end

  # Capture STDOUT to a string
  # @returns [String] the redirected output
  def capture(&block)
    stdout, stderr = StringIO.new, StringIO.new
    $stdout, $stderr = stdout, stderr

    result = block.call

    $stdout, $stderr = STDOUT, STDERR
    $stdout.flush
    $stderr.flush

    return OpenStruct.new(result: result, stdout: stdout.string, stderr: stderr.string)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
