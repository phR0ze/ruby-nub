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
require_relative '../lib/nub/hash'

class TestString < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
  end

  def test_hash_deep_merge
    a = {foo1: 1, foo2: {foo3: 3, foo4: 4}}
    b = {foo1: 1, foo2: {foo3: 5}}
    assert_equal({foo1: 1, foo2: {foo3: 5, foo4: 4}}, a.deep_merge(b))
  end

  def test_hash_deep_merge
    a = {foo1: 1, foo2: {foo3: 3, foo4: 4}}
    b = {foo1: 1, foo2: {foo3: 5}}
    assert_equal({foo1: 1, foo2: {foo3: 5, foo4: 4}}, a.deep_merge(b))
  end

  def test_hash_deep_merge_inplace
    a = {foo1: 1, foo2: {foo3: 3, foo4: 4}}
    b = {foo1: 1, foo2: {foo3: 5}}

    a.deep_merge(b)
    assert({foo1: 1, foo2: {foo3: 5, foo4: 4}} != a)
    assert({foo1: 1, foo2: {foo3: 5, foo4: 4}} == a.deep_merge(b))

    a.deep_merge!(b)
    assert_equal({foo1: 1, foo2: {foo3: 5, foo4: 4}}, a)
  end

  def test_hash_deep_merge_build
    a = {
      "type" => "container",
      "multilib" => true,
      "docker" => {
        "params" => '-e TERM=xterm -v /var/run/docker.sock:/var/run/docker.sock --privileged=true',
        "command" => 'bash -c "while :; do sleep 5; done"',
      },
      "apps" => [
        { "install" => "linux", "desc" => "Linux kernel and supporting modules" }
      ]
    }
    b = {
      "apps" => [
        { "install" => "linux-celes"}
      ]
    }

    assert_equal({
      "type" => "container",
      "multilib" => true,
      "docker" => {
        "params" => '-e TERM=xterm -v /var/run/docker.sock:/var/run/docker.sock --privileged=true',
        "command" => 'bash -c "while :; do sleep 5; done"',
      },
      "apps" => [
        { "install" => "linux-celes"}
      ]
    }, a.deep_merge(b))
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
