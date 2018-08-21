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
    ENV['ftp_proxy'] = nil
    ENV['http_proxy'] = nil
    ENV['https_proxy'] = nil
    ENV['no_proxy'] = nil
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

  def test_proxy_export_nil
    assert_nil(Net.proxy_export)
  end

  def test_proxy_export_default
    ENV['http_proxy'] = 'http://proxy.com:8080'
    assert_equal('export http_proxy=http://proxy.com:8080;', Net.proxy_export)
  end

  def test_proxy_export_set
    proxy = "http://proxy.com:8080"
    export = "export ftp_proxy=#{proxy};export http_proxy=#{proxy};export https_proxy=#{proxy};"
    assert_equal(export, Net.proxy_export('http://proxy.com:8080'))
  end
end

class TestMisc < Minitest::Test
  def test_ip_forward_true
    File.stub(:read, '1'){
      assert(Net.ip_forward?)
    }
  end

  def test_ip_forward_false
    File.stub(:read, ''){assert(!Net.ip_forward?)}
    File.stub(:read, '0'){assert(!Net.ip_forward?)}
  end

  def test_primary_nic
    Net.stub(:`, 'default via 1.1.1.1 dev fooeth proto') {
      assert_equal('fooeth', Net.primary_nic)
    }
  end
end

class TestNamespaces < Minitest::Test
  def setup
    ENV['ftp_proxy'] = nil
    ENV['http_proxy'] = nil
    ENV['https_proxy'] = nil
    ENV['no_proxy'] = nil
  end

  def test_namespaces
    Dir.stub(:[], ['/foo/bar1', '/foo/bar2']){
      assert_equal(['bar1', 'bar2'], Net.namespaces)
    }
  end

  def test_nameservers_no_file
    File.stub(:file?, false) {
      assert_equal([], Net.nameservers)
    }
  end

  def test_nameservers_no_args
    File.stub(:file?, true) {
      File.stub(:readlines, ['nameserver 1.1.1.1', 'nameserver 1.0.0.1']) {
        assert_equal(['1.1.1.1', '1.0.0.1'], Net.nameservers)
      }
    }
  end

  def test_nameservers_no_servers
    File.stub(:file?, true) {
      File.stub(:readlines, []) {
        assert_equal([], Net.nameservers)
      }
    }
  end

  def test_nameservers_no_servers_bad_text
    File.stub(:file?, true) {
      File.stub(:readlines, ['foo bar 100', 'fe fi fo']) {
        assert_equal([], Net.nameservers)
      }
    }
  end

  def test_nameservers_target_arg
    filename = 'foobar'
    File.stub(:file?, ->(x){assert_equal(filename, x)}) {
      File.stub(:readlines, []) {
        assert_equal([], Net.nameservers(filename))
      }
    }
  end

  def test_namespace_connectivity_no_ns
    ns = "bob"
    Net.stub(:namespaces, []){
      capture = Sys.capture{Net.namespace_connectivity?(ns, 'google.com')}
      assert(capture.stdout.include?("Namespace #{ns} doesn't exist"))
    }
  end

  def test_namespace_connectivity_ns_exists
    param_check = ->(x, y) {
      assert(x.include?("bash -c 'curl -m"))
      assert(y[:die] == false)
      assert(y[:check] == "200")
    }

    ns = "bob"
    Net.stub(:namespaces, [ns]){
      Sys.stub(:exec_status, param_check) {
        out = Sys.capture{Net.namespace_connectivity?(ns, 'google.com')}.stdout
        assert(out.strip_color.include?("Checking namespace #{ns} for connectivity"))
      }
    }
  end

  def test_namespace_connectivity_proxy
    param_check = ->(x, y) {
      assert(x.include?("http://foobar;curl -m"))
      assert(y[:die] == false)
      assert(y[:check] == "200")
    }

    ns = "bob"
    Net.stub(:namespaces, [ns]){
      Sys.stub(:exec_status, param_check) {
        out = Sys.capture{Net.namespace_connectivity?(ns, 'google.com', 'http://foobar')}.stdout
        assert(out.strip_color.include?("Checking namespace #{ns} for connectivity"))
      }
    }
  end

  def test_namespace_defaults_no_args
    Net.stub(:namespaces, ['one', 'two', 'three']){
      Net.stub(:primary_nic, 'foo1') {
        Net.stub(:nameservers, ['1.1.1.1', '1.0.0.1']) {
          host, guest, net = Net.namespace_defaults
          assert_equal('veth7', host.name)
          assert_equal('192.168.100.7', host.ip)
          assert_equal('veth8', guest.name)
          assert_equal('192.168.100.8', guest.ip)
          assert_equal('192.168.100.0', net.subnet)
          assert_equal('24', net.cidr)
          assert_equal('foo1', net.nic)
          assert_equal(['1.1.1.1', '1.0.0.1'], net.nameservers)
        }
      }
    }
  end

  def test_namespace_defaults_custom
    default_subnet = Net.namespace_subnet
    Net.namespace_subnet = '192.168.10.0'

    Net.stub(:namespaces, ['one', 'two', 'three']){
      Net.stub(:primary_nic, 'foo1') {
        Net.stub(:nameservers, ['1.1.1.1', '1.0.0.1']) {
          host, guest, net = Net.namespace_defaults(host_veth: Net::Veth.new('foo1'), guest_veth: Net::Veth.new(nil, '19foo'))
          assert_equal('foo1', host.name)
          assert_equal('192.168.10.7', host.ip)
          assert_equal('veth8', guest.name)
          assert_equal('19foo', guest.ip)
          assert_equal('192.168.10.0', net.subnet)
          assert_equal('24', net.cidr)
          assert_equal('foo1', net.nic)
          assert_equal(['1.1.1.1', '1.0.0.1'], net.nameservers)
        }
      }
    }

    Net.namespace_subnet = default_subnet
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
