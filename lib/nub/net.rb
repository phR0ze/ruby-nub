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
require_relative 'log'
require_relative 'sys'
require_relative 'module'

# Collection of network related helpers
module Net
  extend self
  mattr_accessor(:agents)

  @@agents = OpenStruct.new({
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

  # Get fresh proxy from environment
  def proxy
    return OpenStruct.new({
      ftp: ENV['ftp_proxy'],
      http: ENV['http_proxy'],
      https: ENV['https_proxy'],
      no: ENV['no_proxy'],
      uri: ENV['http_proxy'] ? ENV['http_proxy'].split(':')[0..-2] * ":" : nil,
      port: ENV['http_proxy'] ? ENV['http_proxy'].split(':').last : nil
    })
  end

  # Check if a proxy is set
  def proxy?
    return !self.proxy.http.nil?
  end

  # Get a shell export string for proxies
  def proxy_export
    if self.proxy?
      (self.proxy.to_h.map{|k,v| (![:uri, :port].include?(k) && v) ? "export #{k}_proxy=#{v}" : nil}.compact * ';') + ";"
    else
      return nil
    end
  end

  # Check if the system is configured for the kernel to forward ip traffic
  def ip_forward?
    return File.read('/proc/sys/net/ipv4/ip_forward').include?('1')
  end

  # ----------------------------------------------------------------------------
  # Namespace related helpers
  # ----------------------------------------------------------------------------

  # Virtual Ethernet NIC object
  # @param name [String] of the veth
  # @param ip [String] of the veth
  Veth = Struct.new(:name, :ip)

  # Network object
  # @param ip [String] of the network
  # @param cidr [String] of the network
  # @param nameservers [Array[String]] to use for new network
  Network = Struct.new(:ip, :cidr, :nameservers)

  # Check that the namespace has connectivity to the outside world
  # using a simple curl on google
  # @param namespace [String] name to use when creating it
  def namespace_connectivity?(namespace)
    success = false
    Log.info("Checking namespace #{namespace.colorize(:cyan)} for connectivity to google.com", newline:false)

    if File.exists?(File.join("/etc/netns", namespace))
      ping = 'curl -sL -w "%{http_code}" http://www.google.com -o /dev/null'
      return Sys.exec_status("ip netns exec #{namespace} bash -c '#{self.proxy_export}#{ping}'", die:false, check:"200")
    else
      Sys.exec_status(":", die:false, check:"200")
      Log.warn("Namespace #{namespace} doesn't exist!")
    end
  end

  # Create a network namespace with the given name
  # @param namespace [String] name to use when creating it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param guest_veth [Veth] describes the veth to create for the guest side
  # @param network [Network] describes the network to share
  def create_namespace(namespace, host_veth, guest_veth, network)
    namespace_conf = File.join("/etc/netns", namespace)

    # Create new network namespace and start included loopback device
    if !File.exists?(File.join("/var/run/netns", namespace))
      Log.info("Creating VPN Namespace #{namespace.colorize(:cyan)}")
      Sys.exec_status("ip netns add #{namespace}")
    end
    if `ip netns exec #{namespace} ip a`.include?("state DOWN")
      Log.info("Start loopback interface in namespace")
      Sys.exec_status("ip netns exec #{namespace} ip link set lo up")
    end

    # Create a virtual ethernet pair to communicate across namespaces
    # by default they will both be in the root namespace until one is assigned to another
    if !`ip a`.include?(host_veth.name)
      Log.info("Create vpn veths #{host_veth.name.colorize(:cyan)} for #{'root'.colorize(:cyan)}")
      Log.info(" and #{guest_veth.name.colorize(:cyan)} for #{namespace.colorize(:cyan)}", notime:true)
      Sys.exec_status("ip link add #{host_veth.name} type veth peer name #{guest_veth.name}")
      Log.info("Assign veth #{guest_veth.name.colorize(:cyan)} to namespace #{namespace.colorize(:cyan)}")
      Sys.exec_status("ip link set #{guest_veth.name} netns #{namespace}")
    end

    # Assign IPv4 addresses and start up the new veth interfaces
    # sudo ping <vpn1_ip> and sudo netns exec <namespace> ping <vpn0_ip> should work now
    if !`ip a`.include?(host_veth.ip)
      Log.info("Assign ip #{host_veth.ip.colorize(:cyan)} and start #{host_veth.ip.colorize(:cyan)}")
      Sys.exec_status("ifconfig #{host_veth.name} #{File.join(host_veth.ip, nework.cidr)} up")
    end
    if !`ip netns exec #{namespace} ip a`.include?(guest_veth.ip)
      Log.info("Assign ip #{guest_veth.ip.colorize(:cyan)} and start #{guest_veth.ip.colorize(:cyan)}")
      Sys.exec_status("ip netns exec #{namespace} ifconfig #{guest_veth.name} #{File.join(guest_veth.ip, nework.cidr)} up")
    end

    # Share internet access on host with namespace
    # Note: to see current forward rules use: iptables -S
    if !`ip netns exec #{namespace} ip route`.include?('default')
      Log.info("Set default route for traffic leaving namespace to #{host_veth.ip.colorize(:cyan)}")
      Sys.exec_status("ip netns exec #{namespace} ip route add default via #{host_veth.ip} dev #{guest_veth.name}")
    end
    if !`iptables -t nat -S`.include?(File.join(nework.ip, nework.cidr))
      Log.info("Enable NAT on host for vpn net #{File.join(nework.ip, nework.cidr).colorize(:cyan)}")
      Sys.exec_status("iptables -t nat -A POSTROUTING -s #{File.join(nework.ip, nework.cidr)} -o en+ -j MASQUERADE")
    end
    if !`iptables -S`.include?("-A FORWARD -i en+")
      Log.info("Allow forwarding to #{namespace.colorize(:cyan)}")
      Sys.exec_status("iptables -A FORWARD -i en+ -o #{host_veth.name} -j ACCEPT")
    end
    if !`iptables -S`.include?("-A FORWARD -i #{host_veth.name}")
      Log.info("Allow forwarding from #{namespace.colorize(:cyan)}")
      Sys.exec_status("iptables -A FORWARD -i #{host_veth.name} -o en+ -j ACCEPT")
    end

    # Configure secure nameserver to use in VPN namespace
    if !File.exists?(namespace_conf) && network.nameservers
      Log.info("Adding secure nameservers for #{namespace.colorize(:cyan)}")
      Sys.exec_status("mkdir -p /etc/netns/#{namespace}")
      network.nameservers.each{|x|
        Log.info("Adding nameserver #{x.colorize(:cyan)}")
        Sys.exec_status("echo 'nameserver #{x}' >> /etc/netns/#{namespace}/resolv.conf")
      }
    end
  end

  # Delete the given network namespace
  # @param namespace [String] name to use when creating it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param network [Network] describes the network to share
  def delete_namespace(namespace, host_veth, network)
    namespace_conf = File.join("/etc/netns", namespace)

    # Remove nameserver config for vpn
    if File.exists?(namespace_conf)
      Log.info("Removing nameserver config for #{namespace.colorize(:cyan)}")
      Sys.exec_status("rm -rf #{namespace_conf}")
    end

    # Remove NAT and iptables forwarding allowances
    if `iptables -t nat -S`.include?(File.join(network.ip, network.cidr))
      Log.info("Removing NAT on host for vpn net #{File.join(network.ip, network.cidr).colorize(:cyan)}")
      Sys.exec_status("iptables -t nat -D POSTROUTING -s #{File.join(network.ip, network.cidr)} -o en+ -j MASQUERADE")
    end
    if `iptables -S`.include?("-A FORWARD -i en+")
      Log.info("Allow forwarding to #{namespace.colorize(:cyan)}")
      Sys.exec_status("iptables -D FORWARD -i en+ -o #{host_veth.name} -j ACCEPT")
    end
    if `iptables -S`.include?("-A FORWARD -i #{host_veth.name}")
      Log.info("Allow forwarding from #{namespace.colorize(:cyan)}")
      Sys.exec_status("iptables -D FORWARD -i #{host_veth.name} -o en+ -j ACCEPT")
    end

    # Remove virtual ethernet interfaces
    if `ip a`.include?(host_veth.name)
      Log.info("Removing veth interface #{host_veth.name.colorize(:cyan)} for vpn")
      Sys.exec_status("ip link delete #{host_veth.name}")
    end

    # Remove namespace for vpn
    if File.exists?(File.join("/var/run/netns", namespace))
      Log.info("Removing namespace #{namespace.colorize(:cyan)}")
      Sys.exec_status("ip netns delete #{namespace}")
    end
  end

  # Execute in the namespace
  # @param cmd [String] command to execute
  def namespace_exec(cmd)
    return `ip netns exec #{@namespace} bash -c '#{@proxy}#{cmd}'`
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
