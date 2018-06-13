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
require_relative '../lib/nub/sys'
require_relative '../lib/nub/core'

# Intentionally left these out of the automated suite due to the archlinux requirement
class TestPacman < Minitest::Test

  def setup
    @test_dir = File.dirname(File.expand_path(__FILE__))
    @test_data = File.join(@test_dir, 'data')
    @pacman_dir = File.join(@test_dir, '.pacman')
    @pacman_config = File.join(@test_data, 'pacman.conf')
    @pacman_mirror = File.join(@test_data, 'archlinux.mirrorlist')
    FileUtils.rm_rf(@pacman_dir)
    FileUtils.mkdir(@pacman_dir)
  end

  def teardown
    FileUtils.rm_rf(@pacman_dir)
  end

  def test_init
    Pacman.init(@pacman_dir, @pacman_config, @pacman_mirror)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
