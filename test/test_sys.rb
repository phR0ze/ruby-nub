#!/usr/bin/env ruby
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
require 'minitest/autorun'
require_relative '../lib/nub/sys'

class TestSys < Minitest::Test

  def test_caller_filename
    assert_equal("test.rb", Sys.caller_filename)
  end

  def test_capture
    capture = Sys.capture{ puts("test") }
    assert_equal("test\n", capture.stdout)
  end

  def test_strip_colorize
    color = "foo bar".colorize(:cyan) 
    assert("foo bar" != color)
    assert_equal("foo bar", Sys.strip_colorize(color))
  end

  def test_tokenize_colorize
    #colors = [:light_black, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan, :light_white]
    assert_equal([ColorPair.new("foobar", 30, 'black')], Sys.tokenize_colorize("foobar".colorize(:black)))
    assert_equal([ColorPair.new("foobar", 31, 'red')], Sys.tokenize_colorize("foobar".colorize(:red)))
    assert_equal([ColorPair.new("foobar", 32, 'green')], Sys.tokenize_colorize("foobar".colorize(:green)))
    assert_equal([ColorPair.new("foobar", 33, 'yellow')], Sys.tokenize_colorize("foobar".colorize(:yellow)))
    assert_equal([ColorPair.new("foobar", 34, 'blue')], Sys.tokenize_colorize("foobar".colorize(:blue)))
    assert_equal([ColorPair.new("foobar", 35, 'magenta')], Sys.tokenize_colorize("foobar".colorize(:magenta)))
    assert_equal([ColorPair.new("foobar", 36, 'cyan')], Sys.tokenize_colorize("foobar".colorize(:cyan)))
    assert_equal([ColorPair.new("foobar", 37, 'white')], Sys.tokenize_colorize("foobar".colorize(:white)))
    assert_equal([ColorPair.new("foobar", 39, 'gray88')], Sys.tokenize_colorize("foobar".colorize(:default)))
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
