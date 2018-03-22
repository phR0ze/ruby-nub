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
require 'ostruct'

# Collection of simply network related helpers
module Net 
  @@_proxy = nil
  @@_agents = OpenStruct.new({
    windows_ie_6: 'Windows IE 6',
    windows_ie_7: 'Windows IE 7',
    windows_mozilla: 'Windows Mozilla',
    mac_safari: 'Mac Safari',
    mac_firefox: 'Mac FireFox',
    mac_mozilla: 'Mac Mozilla',
    linux_mozilla: 'Linux Mozilla',
    linux_firefox: 'Linux Firefox',
    linux_konqueror: 'Linux Konqueror',
    iphone: 'iPhone'
  })

  # Accessors
  def self.agents; @@_agents; end
  def self.proxy_uri; http_proxy ? http_proxy.split(':')[1][2..-1] : nil; end
  def self.proxy_port; http_proxy ? http_proxy.split(':').last : nil; end
  def self.ftp_proxy; get_proxy if @@_proxy.nil?; @@_proxy['ftp_proxy']; end
  def self.http_proxy; get_proxy if @@_proxy.nil?; @@_proxy['http_proxy']; end
  def self.https_proxy; get_proxy if @@_proxy.nil?; @@_proxy['https_proxy']; end
  def self.no_proxy; get_proxy if @@_proxy.nil?; @@_proxy['no_proxy']; end

  # Get the system proxy variables
  def self.get_proxy
    @@_proxy = {
      'ftp_proxy' => ENV['ftp_proxy'],
      'http_proxy' => ENV['http_proxy'],
      'https_proxy' => ENV['https_proxy'],
      'no_proxy' => ENV['no_proxy']
    }
  end

  # Get a shell export string for proxies
  def self.proxy_export
    get_proxy if @@_proxy.nil?
    return proxy_exist? ? (@@_proxy.map{|k,v| "export #{k}=#{v}"} * ';') + ";" : nil
  end

  # Check if a proxy is set
  def self.proxy_exist?
    get_proxy if @@_proxy.nil?
    return !@@_proxy['http_proxy'].nil?
  end

  # Check if the system is configured for the kernel to forward ip traffic
  def self.ip_forward?
    return `cat /proc/sys/net/ipv4/ip_forward`.include?('1')
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
