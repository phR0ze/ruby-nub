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
require_relative '../lib/utils/thread_comm'

class TestThreadComm < Minitest::Test

  def setup
    @t1 = ThreadComm.new{|comm_in, comm_out|
      while true do
        if !comm_in.empty?
          msg = comm_in.pop
          assert_equal(msg.cmd, 'halt')
          comm_out << ThreadMsg.new('halted')
          break
        end
      end
    }
  end

  def test_msg_with_ThreadMsg
    # Give comm thread some time to run
    sleep(0.01)
    @t1.push(ThreadMsg.new('halt'))

    # Send mesage to comm thread and listen for response
    msg = @t1.pop
    assert_equal(msg.cmd, 'halted')
  end

  def test_msg_with_cmd
    # Give comm thread some time to run
    sleep(0.01)
    @t1.push('halt')

    # Send mesage to comm thread and listen for response
    msg = @t1.pop
    assert_equal(msg.cmd, 'halted')
  end

  def test_msg_with_cmd_and_value
    # Give comm thread some time to run
    sleep(0.01)
    @t1.push('halt', 'value')

    # Send mesage to comm thread and listen for response
    msg = @t1.pop
    assert_equal(msg.cmd, 'halted')
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
