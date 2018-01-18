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

require 'time'
require 'minitest/autorun'
require_relative '../lib/utils/log'

class TestLog < Minitest::Test

  def test_multiaccess
    mock = Minitest::Mock.new
    mock.expect(:sync=, nil, [true])
    mock.expect(:sync=, nil, [true])

    File.stub(:exist?, true){
      File.stub(:open, mock){
        Log.init(path: 'foo.bar')
        id = Log.id
        Log.init(path: 'foo.foo')
        assert_equal(id, Log.id)
      }
    }

    assert_mock(mock)
  end

  def test_queue
    Log.init(queue: true, stdout: false)
    Log.print('foo.bar')
    assert(!Log.empty?)
    msg = Log.pop
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(msg.include?(":: "))
    assert(msg.end_with?('foo.bar'))
    assert(Log.empty?)
  end

  def test_format
    msg = Log.format("foo.bar")
    assert(msg.start_with?(Time.now.utc.strftime('%Y-%m-%d')))
    assert(msg.include?(":: "))
    assert(msg.end_with?('foo.bar'))
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2