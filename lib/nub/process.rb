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

# Monkey patch Process with some useful methods
module Process

  # Get the pid of the process found with the given search term
  # @param term [String] search term to use to find the pid
  def self.pidof(term)
    pid = nil

    str = `ps -ef | grep "[#{term[0]}]#{term[1..-1]}"`
    pid = str.split()[1].to_i if !str.empty?

    return pid
  end

  # Kill the process found with the given search term
  # @param term [String] search term to use to find the pid
  def self.killall(term)
    pid = pidof(term)
    Process.kill("KILL", pid) if pid
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
