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
require_relative '../lib/nub/net'

class TestProxy < Minitest::Test

  def setup
    Log.init(path:nil, queue: false, stdout: true)
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

  def test_ipinc_single
    assert_equal('192.168.100.2', Net.ipinc('192.168.100.1'))
  end

  def test_ipinc_multiple
    assert_equal('192.168.100.9', Net.ipinc('192.168.100.1', 8))
  end

  def test_ipdec_single
    assert_equal('192.168.100.1', Net.ipdec('192.168.100.2'))
  end

  def test_ipdec_multiple
    assert_equal('192.168.100.1', Net.ipdec('192.168.100.9', 8))
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
      Sys.stub(:exec_status, true) {
        out = Sys.capture{Net.namespace_connectivity?(ns, 'google.com')}.stdout
        assert(out.include?("Namespace #{ns} doesn't exist") || out.nil? || out.empty?)
      }
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
        assert(out.strip_color.include?("Checking namespace #{ns} for connectivity") || out.nil? || out.empty?)
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
        assert(out.strip_color.include?("Checking namespace #{ns} for connectivity") || out.nil? || out.empty?)
      }
    }
  end

  def test_namespace_veths
    ns = 'ns1'
    check_params = ->(x){
      if x.include?("#{ns} ip a show type veth")
        "34: ns1_guest@if35: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 7e:cb:fb:61:86:ca brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 192.168.100.2/24 brd 192.168.100.255 scope global ns1_guest
           valid_lft forever preferred_lft forever"
      elsif x == "ip a show type veth"
        "35: ns1_host@if34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 7e:cb:fb:61:86:ca brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 192.168.100.1/24 brd 192.168.100.255 scope global ns1_host
           valid_lft forever preferred_lft forever"
      end
    }
    Net.stub(:namespaces, [ns]) {
      Net.stub(:`, check_params) {
        host, guest = Net.namespace_veths(ns)
        assert_equal(Net::Veth.new("#{ns}_host", '192.168.100.1'), host)
        assert_equal(Net::Veth.new("#{ns}_guest", '192.168.100.2'), guest)
      }
    }
  end

  def test_namespace_next_veth_ips
    ips = ['192.168.100.3', '192.168.100.4']
    veths = [Net::Veth.new(nil, '192.168.100.1'), Net::Veth.new(nil, '192.168.100.2')]
    Net.stub(:namespaces, ['ns1']) {
      Net.stub(:namespace_veths, veths) {
        assert_equal(ips, Net.namespace_next_veth_ips)
      }
    }
  end

  def test_namespace_details
    Net.stub(:namespaces, ['one', 'two', 'three']){
      Net.stub(:primary_nic, 'foo1') {
        Net.stub(:nameservers, ['1.1.1.1', '1.0.0.1']) {
          Net.stub(:namespace_next_veth_ips, ['192.168.100.7', '192.168.100.8']) {
            host, guest, net = Net.namespace_details('ns1')
            assert_equal(Net::Veth.new('ns1_host', '192.168.100.7'), host)
            assert_equal(Net::Veth.new('ns1_guest', '192.168.100.8'), guest)
            assert_equal(Net::Network.new('192.168.100.0', '24', 'foo1', ['1.1.1.1', '1.0.0.1']), net)
          }
        }
      }
    }
  end

  def test_namespace_details_custom
    default_subnet = Net.namespace_subnet
    Net.namespace_subnet = '192.168.10.0'

    Net.stub(:namespaces, ['one', 'two', 'three']){
      Net.stub(:primary_nic, 'foo1') {
        Net.stub(:nameservers, ['1.1.1.1', '1.0.0.1']) {
          Net.stub(:namespace_next_veth_ips, ['192.168.10.11', '192.168.10.12']) {
            host, guest, net = Net.namespace_details('ns1', host_veth: Net::Veth.new('foo1'), guest_veth: Net::Veth.new(nil, '19foo'))
            assert_equal('foo1', host.name)
            assert_equal('192.168.10.11', host.ip)
            assert_equal('ns1_guest', guest.name)
            assert_equal('19foo', guest.ip)
            assert_equal('192.168.10.0', net.subnet)
            assert_equal('24', net.cidr)
            assert_equal('foo1', net.nic)
            assert_equal(['1.1.1.1', '1.0.0.1'], net.nameservers)
          }
        }
      }
    }

    Net.namespace_subnet = default_subnet
  end

  def test_namespace_details_override_list
    host_veth = Net::Veth.new('veth3', '192.168.100.1')
    guest_veth = Net::Veth.new('veth4', '192.168.100.2')
    network = Net::Network.new('192.168.100.0', '24', 'nic1', ['1.1.1.1', '1.0.0.1'])
    Net.stub(:namespace_next_veth_ips, ['192.168.100.1', '192.168.100.2']) {
      host, guest, net = Net.namespace_details('ns1', host_veth, guest_veth, network)
      assert_equal(host_veth, host)
      assert_equal(guest_veth, guest)
      assert_equal(network, net)
    }
  end

  def test_namespace_details_override_hash
    host_veth = Net::Veth.new('veth3', '192.168.100.1')
    guest_veth = Net::Veth.new('veth4', '192.168.100.2')
    network = Net::Network.new('192.168.100.0', '24', 'nic1', ['1.1.1.1', '1.0.0.1'])
    Net.stub(:namespace_next_veth_ips, ['192.168.100.1', '192.168.100.2']) {
      host, guest, net = Net.namespace_details('ns1', guest_veth: guest_veth, network: network, host_veth: host_veth)
      assert_equal(host_veth, host)
      assert_equal(guest_veth, guest)
      assert_equal(network, net)
    }
  end

  def test_namespace_details_exists
    host_veth = Net::Veth.new('one_host', '192.168.100.7')
    guest_veth = Net::Veth.new('one_guest', '192.168.100.8')
    Net.stub(:namespace_veths, [host_veth, guest_veth]){
      Net.stub(:namespaces, ['one', 'two', 'three']){
        Net.stub(:primary_nic, 'foo1') {
          Net.stub(:nameservers, ['1.1.1.1', '1.0.0.1']) {
            Net.stub(:namespace_next_veth_ips, ['192.168.100.1', '192.168.100.2']) {
              host, guest, net = Net.namespace_details('one')
              assert_equal(host_veth, host)
              assert_equal(guest_veth, guest)
              assert_equal(Net::Network.new('192.168.100.0', '24', 'foo1', ['1.1.1.1', '1.0.0.1']), net)
            }
          }
        }
      }
    }
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
