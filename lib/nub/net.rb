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
require 'ipaddr'
require 'socket'
require 'timeout'
require_relative 'log'
require_relative 'sys'
require_relative 'module'

# Collection of network related helpers
module Net
  extend self
  mattr_accessor(:agents)
  mattr_accessor(:namespace_subnet, :namespce_cidr)

  @@namespace_cidr = "24"
  @@namespace_subnet  = "192.168.100.0"

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

  # Determine the primary nic on the machine
  # based off default routing to google.com
  # @returns [String] nic identified as primary
  def primary_nic
    out = `ip route`
    return out[/default via.*dev (.*) proto/, 1]
  end

  # Increment the given ip address
  # @param ip [String] ip address to increment
  # @param i [int] optionally increment by given number
  # @returns [String] incremented ip
  def ipinc(ip, *args)
    i = args.any? ? args.first.to_i : 1
    ip_i = IPAddr.new(ip).to_i + i
    return [24, 16, 8, 0].collect{|x| (ip_i >> x) & 255}.join('.')
  end

  # Decrement the given ip address
  # @param ip [String] ip address to decrement
  # @param i [int] optionally decrement by given number
  # @returns [String] decremented ip
  def ipdec(ip, *args)
    i = args.any? ? args.first.to_i : 1
    ip_i = IPAddr.new(ip).to_i - i
    return [24, 16, 8, 0].collect{|x| (ip_i >> x) & 255}.join('.')
  end

  # Check if the given ip:port is open
  # @param ip [String] to check
  # @param port [Int] to check
  # @param timeout [Int] to wait when dead
  def port_open?(ip, port, *args)
    sec = args.any? ? args.first.to_i : 0.1
    Timeout::timeout(sec){
      begin
        TCPSocket.new(ip, port).close
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        false
      end
    }
  rescue Timeout::Error
    false
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
  # @param nic [String] to use for NAT, true pics primary
  # @param nameservers [Array[String]] to optionally use for new network else uses hosts
  Network = Struct.new(:subnet, :cidr, :nic, :nameservers)

  # Get all namespaces
  # @returns [Array] of namespace names
  def namespaces
    return Dir[File.join("/var/run/netns", "*")].map{|x| File.basename(x)}
  end

  # Get the current nameservers in use
  # @param filename [String] to use instead of /etc/resolv.conf
  # @returns [Array] of name server ips
  def nameservers(*args)
    filename = args.any? ? args.first.to_s : '/etc/resolv.conf'
    filename = '/etc/resolv.conf' if !File.file?(filename)

    result = []
    if File.file?(filename)
      File.readlines(filename).each{|line|
        if line[/nameserver/]
          result << line[/nameserver\s+(.*)/, 1]
        end
      }
    end
    return result
  end

  # Check that the namespace has connectivity to the outside world
  # using a simple curl on google
  # @param namespace [String] name to use when creating it
  # @param target [String] ip or dns name to use for check
  # @param proxy [String] to use rather than default
  def namespace_connectivity?(namespace, target, *args)
    success = false
    proxy = args.any? ? args.first.to_s : nil
    Log.info("Checking namespace #{namespace.colorize(:cyan)} for connectivity to #{target}", newline:false)

    if self.namespaces.include?(namespace)
      ping = "curl -m 3 -sL -w \"%{http_code}\" #{target} -o /dev/null"
      return Sys.exec_status("ip netns exec #{namespace} bash -c '#{self.proxy_export(proxy)}#{ping}'", die:false, check:"200")
    else
      Sys.exec_status(":", die:false, check:"200")
      Log.warn("Namespace #{namespace} doesn't exist!")
    end
  end

  # Get veths for namespace
  # @param namespace [String] name to use for lookup
  # @returns [host_veth, guest_veth]
  def namespace_veths(namespace)
    host, guest = Veth.new, Veth.new
    if self.namespaces.include?(namespace)

      # Lookup guest side
      out = `ip netns exec #{namespace} ip a show type veth`
      host_i = out[/([\d]+):\s+.*@if[\d]+/, 1]
      if host_i
        guest.name = out[/ (.*)@if[\d]+/, 1]
        guest.ip = out[/inet\s+([\d]+\.[\d]+\.[\d]+\.[\d]+).*/, 1]

        # Lookup host side
        out = `ip a show type veth`
        host.name = out[/ (.*)@if#{host_i}/, 1]
        host_ip = out[/inet(.*)#{host.name}/, 1][/\s*([\d]+\.[\d]+\.[\d]+\.[\d]+\/[\d]+).*/, 1]
        host.ip = host_ip[/(.*)\/[\d]+/, 1]
      end
    end

    return host, guest
  end

  # Get next available pair of veth ips
  # @returns ips [Array] of next available ips
  def namespace_next_veth_ips
    used = []
    self.namespaces.each{|ns|
      used += self.namespace_veths(ns).select{|x| x.ip}.map{|x| x.ip.split('.').last.to_i}
    }
    return ((1..255).to_a - used)[0..1].map{|x| self.ipinc(@@namespace_subnet, x)}
  end

  # Get namespace details using defaults for missing arguments
  # veth names are generated using the '<ns>_<type>' naming pattern
  # veth ips are generated based off @@namespace_subnet/@@namespace_cidr incrementally
  # network subnet and cidr default and namespaces and nic are looked up
  # @param namespace [String] name to use for details
  # @returns [host_veth, guest_veth, network]
  def namespace_details(namespace, *args)
    host_veth, guest_veth = Veth.new, Veth.new
    network = Network.new(@@namespace_subnet, @@namespace_cidr, true)

    # Pull from existing namespace first
    if self.namespaces.include?(namespace)
      network.nameservers = self.nameservers("/etc/netns/#{namespace}/resolv.conf")
      host_veth, guest_veth = self.namespace_veths(namespace)

    # Handle args as either as positional or named
    else
      if args.size == 1 && args.first.is_a?(Hash)
        network = args.first[:network] if args.first.key?(:network)
        host_veth = args.first[:host_veth] if args.first.key?(:host_veth)
        guest_veth = args.first[:guest_veth] if args.first.key?(:guest_veth)
      else args.any?
        host_veth = args.shift
        guest_veth = args.shift if args.any?
        network = args.shift if args.any?
      end
    end

    # Populate missing information
    host_veth.name = "#{namespace}_host" if !host_veth.name
    guest_veth.name = "#{namespace}_guest" if !guest_veth.name
    network.subnet = @@namespace_subnet if !network.subnet
    network.cidr = @@namespace_cidr if !network.cidr
    network.nic = self.primary_nic if network.nic.nil? || network.nic == true
    network.nameservers = self.nameservers if !network.nameservers
    if !host_veth.ip or !guest_veth.ip
      host_ip, guest_ip = self.namespace_next_veth_ips
      host_veth.ip = host_ip if !host_veth.ip
      guest_veth.ip = guest_ip if !guest_veth.ip
    end

    return host_veth, guest_veth, network
  end

  # Create a network namespace with the given name
  # Params can be given as ordered positional args or named args
  #
  # @param namespace [String] name to use when creating it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param guest_veth [Veth] describes the veth to create for the guest side
  # @param network [Network] describes the network to share.
  #   If the nic param is nil NAT is not enabled. If nic is true then the primary nic is dynamically
  #   looked up else use user given If nameservers are not given the host nameservers will be used
  def create_namespace(namespace, *args)
    host_veth, guest_veth, network = self.namespace_details(namespace, *args)

    # Ensure namespace i.e. /var/run/netns/<namespace> exists
    if !self.namespaces.include?(namespace)
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
    if network.nic
      if !`iptables -t nat -S`.include?(File.join(network.subnet, network.cidr))
        Log.info("Enable NAT on host for namespace #{File.join(network.subnet, network.cidr).colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -t nat -A POSTROUTING -s #{File.join(network.subnet, network.cidr)} -o #{network.nic} -j MASQUERADE")
      end
      if !`iptables -S`.include?("-A FORWARD -i #{network.nic}")
        Log.info("Allow forwarding to #{namespace.colorize(:cyan)} from #{network.nic.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -A FORWARD -i #{network.nic} -o #{host_veth.name} -j ACCEPT")
      end
      if !`iptables -S`.include?("-A FORWARD -i #{host_veth.name}")
        Log.info("Allow forwarding from #{namespace.colorize(:cyan)} to #{network.nic.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -A FORWARD -i #{host_veth.name} -o #{network.nic} -j ACCEPT")
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
  # Params can be given as ordered positional args or named args
  #
  # @param namespace [String] name to use when deleting it
  # @param host_veth [Veth] describes the veth to create for the host side
  # @param guest_veth [Veth] describes the veth to create for the guest side
  # @param network [Network] describes the network to share.
  #   If the nic param is nil NAT is not enabled. If nic is true then the primary nic is dynamically
  #   looked up else use user given If nameservers are not given the host nameservers will be used
  def delete_namespace(namespace, *args)
    host_veth, guest_veth, network = self.namespace_details(namespace, *args)

    # Remove nameserver config for network namespace
    namespace_conf = File.join("/etc/netns", namespace)
    if File.exists?(namespace_conf)
      Log.info("Removing nameserver config #{namespace_conf.colorize(:cyan)}", newline:false)
      Sys.exec_status("rm -rf #{namespace_conf}")
    end

    # Remove NAT and iptables forwarding allowances
    if network.nic
      if `iptables -t nat -S`.include?(File.join(network.subnet, network.cidr))
        Log.info("Removing NAT on host for namespace #{File.join(network.subnet, network.cidr).colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -t nat -D POSTROUTING -s #{File.join(network.subnet, network.cidr)} -o #{network.nic} -j MASQUERADE")
      end
      if `iptables -S`.include?("-A FORWARD -i #{network.nic} -o #{host_veth.name}")
        Log.info("Remove forwarding to #{namespace.colorize(:cyan)} from #{host_veth.ip.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -D FORWARD -i #{network.nic} -o #{host_veth.name} -j ACCEPT")
      end
      if `iptables -S`.include?("-A FORWARD -i #{host_veth.name} -o #{network.nic}")
        Log.info("Remove forwarding from #{namespace.colorize(:cyan)} to #{host_veth.ip.colorize(:cyan)}", newline:false)
        Sys.exec_status("iptables -D FORWARD -i #{host_veth.name} -o #{network.nic} -j ACCEPT")
      end
    end

    # Remove veths (virtual ethernet interfaces)
    if `ip a`.include?(host_veth.name)
      Log.info("Removing veth interface #{host_veth.name.colorize(:cyan)} for namespace", newline:false)
      Sys.exec_status("ip link delete #{host_veth.name}")
    end

    # Remove namespace
    if self.namespaces.include?(namespace)
      Log.info("Removing namespace #{namespace.colorize(:cyan)}", newline:false)
      Sys.exec_status("ip netns delete #{namespace}")
    end
  end

  # Execute in the namespace
  # @param namespace [String] to execut within
  # @param cmd [String] command to execute
  # @param proxy [String] to use rather than default
  def namespace_exec(namespace, cmd, *args)
    proxy = args.any? ? args.first.to_s : nil
    return `ip netns exec #{namespace} bash -c '#{self.proxy_export(proxy)}#{cmd}'`
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
