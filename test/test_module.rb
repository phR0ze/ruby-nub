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
require_relative '../lib/nub/log'
require_relative '../lib/nub/module'

module Foo
  extend self
  @@foo1 = 'foo1'
  mattr_reader(:foo1)
  mattr_writer(:foo1)
  mattr_accessor(:foo2)

  def setval_with_self
    self.foo1 = 'bob2'
  end

  def setval_with_at_at
    @@foo1 = 'bob3'
  end
end

class Other
  def foo1
    return Foo.foo1
  end
end

class TestModule < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
  end

  def test_mattr_reader_writer
    # Validate default value
    assert_equal('foo1', Foo.foo1)

    # Test writer/reader
    Foo.foo1 = 'bob'
    assert_equal('bob', Foo.foo1)

    # Test other class context
    other = Other.new
    assert_equal('bob', other.foo1)

    # Set value with self in module and check externally
    Foo.setval_with_self
    assert_equal('bob2', Foo.foo1)
    assert_equal('bob2', other.foo1)

    # Set value with at at in module and check externally
    Foo.setval_with_at_at
    assert_equal('bob3', Foo.foo1)
    assert_equal('bob3', other.foo1)
  end

  def test_mattr_accessor
    assert_nil(Foo.foo2)
    Foo.foo2 = 'bob'
    assert_equal('bob', Foo.foo2)
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
