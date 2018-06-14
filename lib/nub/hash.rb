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

# Monkey patch string with some useful methods
class Hash

  # Deep merge hash with other
  # @param other [Hash] other hash to merge with
  def deep_merge(other)
    merge(other){|k, av, bv|
      if av.is_a?(Hash) && bv.is_a?(Hash)
        av.deep_merge(bv)
      else
        bv
      end
    }
  end

  # Deep merge hash with other
  # @param other [Hash] other hash to merge with
  def deep_merge!(other)
    merge!(other){|k, av, bv|
      if av.is_a?(Hash) && bv.is_a?(Hash)
        av.deep_merge!(bv)
      else
        bv
      end
    }
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
