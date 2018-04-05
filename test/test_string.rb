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
require_relative '../lib/nub/string'

class TestString < Minitest::Test

  def test_strip_color
    color = "foo bar".colorize(:cyan)
    assert("foo bar" != color)
    assert_equal("foo bar", color.strip_color)
  end

  def test_to_ascii
    assert_equal("test", "test".to_ascii)
  end

  def test_tokenize_color
    #colors = [:light_black, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan, :light_white]
    assert_equal([ColorPair.new("foobar", 30, 'black')], "foobar".colorize(:black).tokenize_color)
    assert_equal([ColorPair.new("foobar", 31, 'red')], "foobar".colorize(:red).tokenize_color)
    assert_equal([ColorPair.new("foobar", 32, 'green')], "foobar".colorize(:green).tokenize_color)
    assert_equal([ColorPair.new("foobar", 33, 'yellow')], "foobar".colorize(:yellow).tokenize_color)
    assert_equal([ColorPair.new("foobar", 34, 'blue')], "foobar".colorize(:blue).tokenize_color)
    assert_equal([ColorPair.new("foobar", 35, 'magenta')], "foobar".colorize(:magenta).tokenize_color)
    assert_equal([ColorPair.new("foobar", 36, 'cyan')], "foobar".colorize(:cyan).tokenize_color)
    assert_equal([ColorPair.new("foobar", 37, 'white')], "foobar".colorize(:white).tokenize_color)
    assert_equal([ColorPair.new("foobar", 39, 'gray88')], "foobar".colorize(:default).tokenize_color)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
