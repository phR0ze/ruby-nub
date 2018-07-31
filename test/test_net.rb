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
require_relative '../lib/nub/net'

class TestProxy < Minitest::Test

  def setup
    ENV['http_proxy'] = nil
  end

  def test_agents
    assert_equal(Net.agents.windows_ie_6, 'Windows IE 6')
    assert_equal(Net.agents.iphone, 'iPhone')
  end

  def test_unset_proxy?
    assert(!Net.proxy?)
  end

  def test_set_proxy?
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert(Net.proxy?)
  end

  def test_proxy_uri
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert_equal('http://proxy.com:8080', Net.proxy.http)
  end

  def test_proxy_uri
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert_equal('http://proxy.com', Net.proxy.uri)
  end

  def test_proxy_port
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert_equal('8080', Net.proxy.port)
  end

  def test_proxy_export
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert_equal('export http_proxy=http://proxy.com:8080;', Net.proxy_export)
  end

  def test_ip_forward_true
    File.stub(:read, '1'){
      assert(Net.ip_forward?)
    }
  end

  def test_ip_forward_false
    File.stub(:read, ''){assert(!Net.ip_forward?)}
    File.stub(:read, '0'){assert(!Net.ip_forward?)}
  end

  def test_namespace_connectivity_false
    File.stub(:exists?, false){
      capture = Sys.capture{Net.namespace_connectivity?('bob')}
      assert(capture.stdout.include?("Namespace bob doesn't exist"))
    }
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
