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

require 'ostruct'

# Provides a simple messaging mechanism between threads
ThreadMsg = Struct.new(:cmd, :value)

# Thread with communication queues for simple messaging
class ThreadComm < Thread
  def initialize
    @comm_in = Queue.new
    @comm_out = Queue.new

    # Proc.new will return the block given to this method
    # pass it along to thread .new with arguments
    super(@comm_in, @comm_out, &Proc.new)
  end

  # Check if the message queue is empty
  def empty?
    return @comm_out.empty?
  end

  # Pop a message off the thread's queue or block
  def pop
    return @comm_out.pop
  end

  # Push the given message onto the threads incoming queue
  # @param msg [ThreadMsg] message to the thread
  def push(msg)
    @comm_in << msg
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
