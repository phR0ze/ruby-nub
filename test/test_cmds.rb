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

require 'minitest/autorun'
require_relative '../lib/utils/cmds'

class TestCmds < Minitest::Test

  def test_hypens_to_underscores_in_command
    ARGV.clear and ARGV << 'fix-links'
    opts = Cmds.new('test', '0.1.2', "")
    opts.add('fix-links', 'Test hypend commands', [
      CmdOpt.new('--all', 'List all info'),
    ])
    opts.parse!
    assert(opts[:fix_links])
  end

  def test_updating_options
    ARGV.clear and ARGV << 'fix-links'
    opts = Cmds.new('test', '0.1.2', "")
    opts.add('fix-links', 'Test hypend commands', [
      CmdOpt.new('--all', 'List all info'),
    ])
    opts.parse!
    assert(!opts[:bob])
    opts[:bob] = true
    assert(opts[:bob])
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
