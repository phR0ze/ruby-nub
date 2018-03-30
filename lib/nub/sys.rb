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

ColorPair = Struct.new(:str, :color_code, :color_name)
ColorMap = {
  30 => "black",
  31 => "red",
  32 => "green",
  33 => "yellow",
  34 => "blue",
  35 => "magenta",
  36 => "cyan",
  37 => "white",
  39 => "gray88"   # default
}

module Sys

  # Capture STDOUT to a string
  # @returns [String] the redirected output
  def self.capture(&block)
    stdout, stderr = StringIO.new, StringIO.new
    $stdout, $stderr = stdout, stderr

    result = block.call

    $stdout, $stderr = STDOUT, STDERR

    return OpenStruct.new(result: result, stdout: stdout.string, stderr: stderr.string)
  end

  # Wait for any key to be pressed  
  def self.any_key?
    begin
      state = `stty -g`
      `stty raw -echo -icanon isig`
      STDIN.getc.chr
    ensure
      `stty #{state}`
    end
  end

  # Strip the ansi color codes from the given string
  # @param str [String] string with ansi color codes
  # @returns [String] string without any ansi codes
  def self.strip_colorize(str)
    return str.gsub(/\e\[0;[39]\d;49m/, '').gsub(/\e\[0m/, '')
  end

  # Tokenize the given colorized string
  # @param str [String] string with ansi color codes
  # @returns [Array] array of Token
  def self.tokenize_colorize(str)
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
      tokens << ColorPair.new(token, color.to_i, ColorMap[color.to_i])
    end

    return tokens
  end

end

# vim: ft=ruby:ts=2:sw=2:sts=2
