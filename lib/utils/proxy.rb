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

module Proxy
  @@_proxy = nil

  # Accessors
  def self.ftp; get if @@_proxy.nil?; @@_proxy['ftp_proxy']; end
  def self.http; get if @@_proxy.nil?; @@_proxy['http_proxy']; end
  def self.https; get if @@_proxy.nil?; @@_proxy['https_proxy']; end
  def self.no; get if @@_proxy.nil?; @@_proxy['no_proxy']; end

  # Get the system proxy variables
  def self.get
    @@_proxy = {
      'ftp_proxy' => ENV['ftp_proxy'],
      'http_proxy' => ENV['http_proxy'],
      'https_proxy' => ENV['https_proxy'],
      'no_proxy' => ENV['no_proxy']
    }
  end

  # Get a shell export string for proxies
  def self.export
    return exist? ? (@@_proxy.map{|k,v| "export #{k}=#{v}"} * ';') + ";" : nil
  end

  # Check if a proxy is set
  def self.exist?
    get if @@_proxy.nil?
    return !@@_proxy['http_proxy'].nil?
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
