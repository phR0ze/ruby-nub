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
  # @param proxy [String] to use rather than default
  def proxy_export(*args)
    proxy = args.any? ? args.first.to_s : nil
    if proxy
      ({'ftp_proxy' => proxy,
       'http_proxy' => proxy,
       'https_proxy' => proxy
      }.map{|k,v| "export #{k}=#{v}"} * ';') + ";"
    elsif self.proxy?
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
  # @param name [String] of the veth e.g. veth1
  # @param ip [String] of the veth e.g. 192.168.100.1
  Veth = Struct.new(:name, :ip)

  # Network object
  # @param subnet [String] of the network e.g. 192.168.100.0
  # @param cidr [String] of the network
  # @param nameservers [Array[String]] to optionally use for new network else uses hosts
  Network = Struct.new(:subnet, :cidr, :nameservers)

  # Check that the namespace has connectivity to the outside world
  # using a simple curl on google
  # @param namespace [String] name to use when creating it
  # @param target [String] ip or dns name to use for check
  # @param proxy [String] to use rather than default
  def namespace_connectivity?(namespace, target, *args)
    success = false
    proxy = args.any? ? args.first.to_s : nil
    Log.info("Checking namespace #{namespace.colorize(:cyan)} for connectivity to #{target}", newline:false)

    if File.exists?(File.join("/var/run/netns", namespace))
      ping = "curl -m 3 -sL -w \"%{http_code}\" #{target} -o /dev/null"
      return Sys.exec_status("ip netns exec #{namespace} bash -c '#{self.proxy_export(proxy)}#{ping}'", die:false, check:"200")
    else
      Sys.exec_status(":", die:false, check:"200")
      Log.warn("Namespace #{namespace} doesn't exist!")
    end
  end

  # Get the current nameservers in use
  # parses /etc/resolv.conf
  def nameservers
    result = []
    resolv = "/etc/resolv.conf"
    if File.file?(resolv)
      File.readlines(resolv).each{|line|
        if line[/nameserver/]
          result << line[/nameserver\s+(.*)/, 1]
        end
      }
    end
    return result
  end

  # Create a network namespace with the given name
  # @param namespace [String] name to use when creating it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param guest_veth [Veth] describes the veth to create for the guest side
  # @param network [Network] describes the network to share
  # @param nat [String] pattern matching nic to nat against e.g. en+
  def create_namespace(namespace, host_veth, guest_veth, network, *args)
    nat = args.any? ? args.first.to_s : nil
    namespace_conf = File.join("/etc/netns", namespace)
    network.nameservers = self.nameservers if not network.nameservers

    # Ensure namespace i.e. /var/run/netns/<namespace> exists
    if !File.exists?(File.join("/var/run/netns", namespace))
      Log.info("Creating Network Namespace #{namespace.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip netns add #{namespace}")
    end

    # Ensure loopback device is running inside the pnamespace
    if `ip netns exec #{namespace} ip a`.include?("state DOWN")
      Log.info("Start loopback interface in namespace", newline:false)
      Sys.exec_status("ip netns exec #{namespace} ip link set lo up")
    end

    # Create a virtual ethernet pair to communicate across namespaces
    # by default they will both be in the root namespace until one is assigned to another
    # e.g. host:192.168.100.1 and guest:192.168.100.2 communicating in network:192.168.100.0
    if !`ip a`.include?(host_veth.name)
      msg = "Create namespace veths #{host_veth.name.colorize(:cyan)} for #{'root'.colorize(:cyan)} "
      msg += "and #{guest_veth.name.colorize(:cyan)} for #{namespace.colorize(:cyan)}"
      Log.info(msg, newline:false)
      Sys.exec_status("ip link add #{host_veth.name} type veth peer name #{guest_veth.name}")
      Log.info("Assign veth #{guest_veth.name.colorize(:cyan)} to namespace #{namespace.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip link set #{guest_veth.name} netns #{namespace}")
    end

    # Assign IPv4 addresses and start up the new veth interfaces
    # sudo ping #{host_veth.ip} and sudo netns exec #{namespace} ping #{guest_veth.ip} should work now
    if !`ip a`.include?(host_veth.ip)
      Log.info("Assign ip #{host_veth.ip.colorize(:cyan)} and start #{host_veth.name.colorize(:cyan)}", newline:false)
      Sys.exec_status("ifconfig #{host_veth.name} #{File.join(host_veth.ip, network.cidr)} up")
    end
    if !`ip netns exec #{namespace} ip a`.include?(guest_veth.ip)
      Log.info("Assign ip #{guest_veth.ip.colorize(:cyan)} and start #{guest_veth.name.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip netns exec #{namespace} ifconfig #{guest_veth.name} #{File.join(guest_veth.ip, network.cidr)} up")
    end

    # Configure host veth as guest's default route leaving namespace
    if !`ip netns exec #{namespace} ip route`.include?('default')
      Log.info("Set default route for traffic leaving namespace #{namespace.colorize(:cyan)} to #{host_veth.ip.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip netns exec #{namespace} ip route add default via #{host_veth.ip} dev #{guest_veth.name}")
    end

    # NAT guest veth behind host veth to share internet access on host with guest
    # Note: to see current forward rules use: sudo iptables -S
    if nat
      if !`iptables -t nat -S`.include?(File.join(network.subnet, network.cidr))
        Log.info("Enable NAT on host for namespace #{File.join(network.subnet, network.cidr).colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -t nat -A POSTROUTING -s #{File.join(network.subnet, network.cidr)} -o #{nat} -j MASQUERADE")
      end
      if !`iptables -S`.include?("-A FORWARD -i #{nat}")
        Log.info("Allow forwarding to #{namespace.colorize(:cyan)} from #{nat.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -A FORWARD -i #{nat} -o #{host_veth.name} -j ACCEPT")
      end
      if !`iptables -S`.include?("-A FORWARD -i #{host_veth.name}")
        Log.info("Allow forwarding from #{namespace.colorize(:cyan)} to #{nat.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -A FORWARD -i #{host_veth.name} -o #{nat} -j ACCEPT")
      end
    end

    # Configure nameserver to use in Network namespace
    namespace_conf = File.join("/etc/netns", namespace)
    if !File.exists?(namespace_conf) && network.nameservers
      Log.info("Creating nameserver config #{namespace_conf}", newline:false)
      Sys.exec_status("mkdir -p #{namespace_conf}")
      network.nameservers.each{|x|
        Log.info("Adding nameserver #{x.colorize(:cyan)} to config", newline:false)
        Sys.exec_status("echo 'nameserver #{x}' >> /etc/netns/#{namespace}/resolv.conf")
      }
    end
  end

  # Delete the given network namespace
  # @param namespace [String] name to use when creating it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param network [Network] describes the network to share
  # @param nat [String] pattern matching nic to nat against e.g. en+
  def delete_namespace(namespace, host_veth, network, *args)
    nat = args.any? ? args.first.to_s : nil

    # Remove nameserver config for network namespace
    namespace_conf = File.join("/etc/netns", namespace)
    if File.exists?(namespace_conf)
      Log.info("Removing nameserver config #{namespace_conf.colorize(:cyan)}", newline:false)
      Sys.exec_status("rm -rf #{namespace_conf}")
    end

    # Remove NAT and iptables forwarding allowances
    if nat
      if `iptables -t nat -S`.include?(File.join(network.subnet, network.cidr))
        Log.info("Removing NAT on host for namespace #{File.join(network.subnet, network.cidr).colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -t nat -D POSTROUTING -s #{File.join(network.subnet, network.cidr)} -o #{nat} -j MASQUERADE")
      end
      if `iptables -S`.include?("-A FORWARD -i #{nat}")
        Log.info("Remove forwarding to #{namespace.colorize(:cyan)} from #{host_veth.ip.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -D FORWARD -i #{nat} -o #{host_veth.name} -j ACCEPT")
      end
      if `iptables -S`.include?("-A FORWARD -i #{host_veth.name}")
        Log.info("Remove forwarding from #{namespace.colorize(:cyan)} to #{host_veth.ip.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -D FORWARD -i #{host_veth.name} -o #{nat} -j ACCEPT")
      end
    end

    # Remove veths (virtual ethernet interfaces)
    if `ip a`.include?(host_veth.name)
      Log.info("Removing veth interface #{host_veth.name.colorize(:cyan)} for namespace", newline:false)
      Sys.exec_status("ip link delete #{host_veth.name}")
    end

    # Remove namespace
    if File.exists?(File.join("/var/run/netns", namespace))
      Log.info("Removing namespace #{namespace.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip netns delete #{namespace}")
    end
  end

  # Execute in the namespace
  # @param namespace [String] to execut within
  # @param cmd [String] command to execute
  # @param proxy [String] to use rather than default
  def namespace_exec(namespace, cmd, proxy:nil)
    return `ip netns exec #{namespace} bash -c '#{self.proxy_export(proxy)}#{cmd}'`
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
