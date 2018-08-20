# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub?branch=master)
[![Gem Version](https://badge.fury.io/rb/nub.svg)](https://badge.fury.io/rb/nub)
[![Coverage Status](https://coveralls.io/repos/github/phR0ze/ruby-nub/badge.svg?branch=master)](https://coveralls.io/github/phR0ze/ruby-nub?branch=master)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

### Table of Contents
* [Deploy](#deploy)
* [Commander Module](#commander-module)
  * [Commands](#commands)
    * [Command Parameters ](#command-paramaters)
    * [Chained Commands](#chained-commands)
  * [Options](#options)
    * [Positional Options](#positional-options)
    * [Value Types](#value-types)
    * [Allowed Values](#allowed-values)
    * [Global Options](#global-options)
  * [Configuration](#configuration)
    * [Named Option Examples](#named-option-examples)
    * [Positional Option Examples](#positional-option-examples)
    * [Chained Command Expression Examples](#chained-command-expression-examples)
  * [Help](#help)
    * [Examples](#examples)
    * [Indicators](#indicators)
* [Config Module](#config-module)
  * [ERB Resolution](#erb-resolution)
* [Core Module](#core-module)
* [FileUtils Extensions](#fileutils-extensions)
* [Hash Module](#hash-module)
* [Log Module](#Log-module)
* [Module Extensions](#module-extensions)
* [Net Module](#net-module)
  * [Network Namespaces](#network-namespaces)
    * [Teamviewer Example](#teamviewer-example)
    * [PIA VPN Example](#pia-vpn-example)
  * [Network Proxy](#network-proxy)
* [Pacman Module](#pacman-module)
* [Process Module](#process-module)
* [Sys Module](#sys-module)
* [ThreadComm Module](#thread-comm-module)
* [User Module](#user-module)
* [Ruby Gem Creation](#ruby-gem-creation)
  * [Package Layout](#package-layout)
  * [Build Gem](#build-gem)
  * [Install Gem](#install-gem)
  * [Push Gem](#push-gem)
* [Integrate with Travis-CI](#integrate-with-travis-ci)
  * [Install Travis Client](#install-travis-client)
  * [Deploy Ruby Gem on Tag](#deploy-ruby-gem-on-tag)
 
## Deploy <a name="deploy"></a>
Run: `bundle install --system`

## Commander Module <a name="commander-module"></a>
Commander was created mainly because all available options parsers seemed overly complicated and
overweight and partly because I enjoyed understanding every bit going into it. Commander offers
***git*** or ***kubectl*** like command syntax.

There are two kinds of paramaters that commander deals with ***commands*** and ***options***.

### Commands <a name="commands"></a>
Commands are specific named parameters that may or may not have options specific to it. Commands
have their own help to display their usage and available options. Commands are used to trigger
different branches of functionality in an application.

#### Command Parameters <a name="command-parameters"></a>
Each command may have zero or more command parameters. Command parameters may be either a
sub-command, which follow the same rules in a recursive fashion as any command, or an option.
Command options modify how the command behaves.

#### Chained Commands <a name="chained-commands"></a>
Chained command expressions allow a cleaner multi-command type expression with reusable options.

Whenever more than one command is used in the command line expression the expression is interpreted
as being a ***chained command expression*** a.k.a ***chained commands***. Chained commands are
executed left to right, such that you can execute the first command then the second command or more
in a single command line expression. Each command in a chained command expression may have its own
specific options (those coming after the command but before the next command) which are taken into
account for the command as usual. However if options are omitted the options from the next command
will be used in the order they are given to satisfy the options of the command before. Only options
of the same type and position will be used.

### Options <a name="options"></a>
Options are additional parameters that are given that modify the behavior of a command. There are
two kinds of options available for use ***positional*** and ***named***.

#### Positional Options <a name="positional-options"></a>
Positional options are identified by the absence of preceding dash/dashes and are interpreted
according to the order in which they were found. Positional options always pass a value into the
application. Positional options are named internally with the command name concatted with a zero
based int representing its order ***e.g. clean0*** where *clean* is the command name and *0* is the
positional options order given during configuration. Positional options are given sequentially so
you can't skip one and specify the second, it must be one then two etc...

#### Named Options
Named options have a name that is prefixed with a dash (short hand) or two dashes (long hand) e.g.
***-h*** or ***--help*** and may be a value passed in or simply a boolean flag. **Long Hand** form
is always required for named options, short hand may or may not be given. An incoming
**value/values** are indicated by the hint configuration e.g. ***-s|--skip=COMPONENTS*** indicates
there is an incoming value/values to be expected because of the hint ***COMPONENTS***.

#### Value Types <a name="value-types"></a>
Option values require a ***type*** so that Commander can interpret how to use them. The supported
value types are ***true, false, Integer, String, Array***. Positional options default to
type String while named options default to false. The named option flag default of false can be
changed to default to true by setting the ***type:true*** configuration param.

#### Allowed Values <a name="allowed-values"></a>
Commander will check the values given against an allowed list if so desired. This is done via the 
***allowed*** configuration parameter.

#### Global Options <a name="global-options"></a>
***Global*** options are options that are added with the ***add_global*** function and will show up
set in the command results using the ***:global*** symbol. Global positional options must be given
before any other commands but global named options may appear anywhere in the command line
expression.

### Configuration <a name="configuration"></a>
***Commander.new*** must be run from the app's executable file for it to pick up the app's filename
properly.

Example ruby configuration:
```ruby
if __FILE__ == $0
  # Create examples for app
  app = 'reduce'
  examples = "Full ISO Build: sudo ./#{app} clean build all -p personal\n".colorize(:green)
  examples += "Rebuild initramfs: sudo ./#{app} clean build initramfs,iso -p personal\n".colorize(:green)
  examples += "Rebuild multiboot: sudo ./#{app} clean build multiboot,iso -p personal\n".colorize(:green)
  examples += "Clean pacman dbs: sudo ./#{app} clean --pacman\n".colorize(:green)
  examples += "Build k8snode deployment: sudo ./#{app} clean build iso -d k8snode -p personal\n".colorize(:green)
  examples += "Pack k8snode deployment: ./#{app} pack k8snode\n".colorize(:green)
  examples += "Deploy nodes: sudo ./#{app} deploy k8snode 10,11,12\n".colorize(:green)
  examples += "Deploy container: sudo ./#{app} deploy build --run\n".colorize(:green)

  # Create a new instance of commander
  cmdr = Commander.new(app:app, version:'0.0.1', examples:examples)
  cmdr.add_global('-p|--profile=PROFILE', 'Profile to use', type:String)
  cmdr.add('info', 'List build info')
  cmdr.add('list', 'List out components', nodes:[
    Option.new(nil, 'Components to list', type:Array, allowed:{
      all: 'List all components',
      boxes: 'List all boxes',
      isos: 'List all isos',
      images: 'List all docker images'
    }),
    Option.new('--raw', "Produce output suitable for automation"),
  ])
  cmdr.add('clean', 'Clean ISO components', nodes:[
    Option.new(nil, 'Components to clean', type:Array, allowed:{
      all: 'Clean all components including deployments',
      initramfs: 'Clean initramfs image',
      multiboot: 'Clean grub multiboot image',
      iso: 'Clean bootable ISO'
    }),
    Option.new('--pacman', "Clean pacman repos"),
    Option.new('--cache', "Clean pacman/ruby package cache"),
    Option.new('--vms', "Clean VMs that are no longer deployed"),
    Option.new('-d|--deployments=DEPLOYMENTS', "Deployments to clean", type:Array)
  ])
  cmdr.add('build', 'Build ISO components', nodes:[
    Option.new(nil, 'Components to build', type:Array, allowed:{
      all: 'Build all components including deployments',
      initramfs: 'Build initramfs image',
      multiboot: 'Build grub multiboot image',
      iso: 'Clean bootable ISO',
    }),
    Option.new('-d|--deployments=DEPLOYMENTS', "Deployments to build", type:Array)
  ])
  cmdr.add('pack', 'Pack ISO deployments into vagrant boxes', nodes:[
    Option.new(nil, "Deployments to pack", type:Array, required:true),
    Option.new('--disk-size=DISK_SIZE', "Set the disk size in MB e.g. 10000", type:String),
    Option.new('--force', "Pack the given deployment/s even if they already exist")
  ])
  cmdr.add('deploy', 'Deploy VMs or containers', nodes:[
    Option.new(nil, "Deployments to pack", type:Array, required:true),
    Option.new(nil, "Comma delimited list of last octet IPs (e.g. 10,11,12", type:Array),
    Option.new('-n|--name=NAME', "Give a name to the nodes being deployed", type:String),
    Option.new('-f|--force', "Deploy the given deployment/s even if they already exist"),
    Option.new('-r|--run', "Run the container with defaults"),
    Option.new('-e|--exec=CMD', "Specific command to run in container", type:String),
    Option.new('--ipv6', "Enable IPv6 on the given nodes"),
    Option.new('--vagrantfile', "Export the Vagrantfile only"),
  ])

  # Invoke commander parse
  cmdr.parse!

  # Execute 'info' command
  reduce.info if cmdr[:info]

  # Execute 'list' command
  reduce.list(cmdr[:list][:list0]) if cmdr[:list]

  # Execute 'clean' command
  reduce.clean(cmdr[:clean][:clean0], deployments: cmdr[:clean][:deployments],
    pacman: cmdr[:clean][:pacman], cache: cmdr[:clean][:cache], vms: cmdr[:vms]) if cmdr[:clean]

  # Execute 'build' command
  reduce.build(cmdr[:clean][:clean0], deployments: cmdr[:clean][:deployments]) if cmdr[:build]

  # Execute 'pack' command
  reduce.pack(cmdr[:pack][:pack0], disksize: cmdr[:pack][:disksize], force: cmdr[:pack][:force]) if cmdr[:pack]

  # Execute 'deploy' command
  reduce.deploy(cmdr[:deploy][:pack0], nodes: cmdr[:deploy][:deploy1], name: cmdr[:deploy][:name],
    run: cmdr[:deploy][:run], exec: cmdr[:deploy][:exec], ipv6: cmdr[:ipv6],
    vagrantfile: cmdr[:vagrantfile], force: cmdr[:force]) if cmdr[:deploy]
end
```

#### Named Option Examples <a name="named-option-examples"></a>
```bash
# The parameter '-d' coming after the command 'clean' is a named option using short hand form with
# an input type of Array without any checking as configured above
./app clean -d base

# This is a variation using long form which is exactly equivalent
./app clean --deployments base

# This is a variation using long form with assignement syntax which is also exactly equivalent
./app clean --deployments=base

# This is a variation providing multiple values for the array named parameter 'deployments'
./app clean -d base,lite,heavy
```

#### Positional Option Examples <a name="positional-option-examples"></a>
```bash
# The parameter 'all' coming after the command 'clean' is a positional array option with a default
# type of String that is checked against the configured allowed values ['all', 'initramfs',
# 'multiboot', 'ios'].
./app clean all

# This is a variation of the previous command line expression with multiple values specified for the
# array.
./app clean initramfs,multiboot,iso
```

#### Chained Command Expression Examples <a name="chained-command-expression-examples"></a>
```bash
# Chained commands 'clean' and 'build' share the 'all' positional option. Additionally there is one
# global option '-p personal'. Thus 'clean' will be  executed first with the 'all' option in the
# context of '-p personal' then the 'build' command will be executed second with the 'all' option
# in the context of '-p personal'.
./app clean build all -p standard

# The above chained command is exactly equivalent to its expanded counter part below
./app clean all build all -p personal
```

### Help <a name="help"></a>
Help for your appliation and commands is automatically supported with the ***-h*** and ***--help***
flags and is generated from the app ***name***, ***version***, ***examples***, ***commands***,
***descriptions*** and ***options*** given in Commander's configuration.

#### Examples <a name="examples"></a>
Examples is just a free form string that is displayed before usage so user's have an idea of how to
put together the commands and options.

#### Indicators <a name="indicators"></a>
Allowed checks, types, and required flags specified in the configuration are known as indicators in
the help context and are added to the end of the option descriptions.

Example ruby configuration:
```ruby
# Creates a new instance of commander with app settings as given
app = 'builder'
examples = "Full Build: ./#{app} clean build all\n".colorize(:green)
examples += "ISO/Image Build: ./#{app} clean build iso,image\n".colorize(:green)
cmdr = Commander.new(app, '0.0.1', examples)
# Create command with a positional argument
cmdr.add('list', 'List components')
cmdr.add('clean', 'Clean components', options:[
  Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image', 'boot'], type:Array),
  Option.new('-d|--debug', 'Debug mode'),
  Option.new('-m|--min=MINIMUM', 'Set the minimum clean', allowed:[1, 2, 3], type:Integer),
  Option.new('-s|--skip=COMPONENTS', 'Skip the given components', allowed:['iso', 'image'], type:Array)
])
# Create command with a single positional option with an allowed check for value
cmdr.add('build', 'Build components', options:[
  Option.new(nil, 'Build given components', allowed:['all', 'iso', 'image', 'boot'], type:Array)
])
cmdr.parse!
```

App help would look like:
```bash
builder_v0.0.1
--------------------------------------------------------------------------------
Examples:
Full Build: ./builder clean build all
Image/ISO Build: ./builder clean build iso,image

Usage: ./builder [commands] [options]
    -h|help                             Print command/options help: Flag
COMMANDS:
    list                                List components
    clean                               Clean components
    build                               Build components

see './builder COMMAND --help' for specific command help
```

Command help for ***./builder list --help*** would look like:
```bash
builder_v0.0.1
--------------------------------------------------------------------------------
List components

Usage: ./builder list [options]
    -h|--help                           Print command/options help: Flag
```

Command help for ***./builder clean --help*** would look like:
```bash
builder_v0.0.1
--------------------------------------------------------------------------------
Clean components

Usage: ./builder clean [options]
    clean0                              Clean given components (all,iso,image,boot): Array, Required
    -h|--help                           Print command/options help: Flag
    -d|--debug                          Debug mode: Flag
    -m|--min=MINIMUM                    Set the minimum clean (1,2,3): Integer
    -s|--skip=COMPONENTS                Skip the given components (iso,image): Array
```

Command help for ***./builder build --help*** would look like:
```bash
builder_v0.0.1
--------------------------------------------------------------------------------
Build components

Usage: ./builder build [options]
    build0                              Build given components (all,iso,image,boot): String, Required
    -h|--help                           Print command/options help
```

## Config Module <a name="config-module"></a>
Config is a simple YAML wrapper with some extra features. Since it implements the ***Singleton***
pattern you can easily use it through out your app without carrying around instances everywhere.
It creates config files in memory and saves them to the config ***~/.config*** directory when saved
unless the given config exists along side the app's path. If the config file already exists it simply reads it.

Initialize once on entry of your app and leverage throughout:
```ruby
Config.init("openvpn.yml")
```

## Core Module <a name="core-module"></a>
The core module provides a few extensions to common ruby types.

### ERB Resolution <a name="erb-resolution"></a>
The ***String*** class has been extended to include ***.erb*** and ***.erb!*** to easily resolve
template variables. Additionally the ***Array*** and ***Hash*** classes have been extended to
recursively resolve template variables with ***.erb*** and ***.erb!*** functions.

Examples:
```ruby
puts("This is a template example <%=foo%>.".erb({'foo': 'foobar'}))
# outputs: This is a template example foobar.
```

## FileUtils Extensions <a name="fileutils-module"></a>

## Hash Module <a name="hash-module"></a>

## Log Module <a name="log-module"></a>

## Module Extensions <a name="module-extensions"></a>

## Net Module <a name="net-module"></a>
The network module is a collection of network related helpers and automation to simplify tasks and
encapsulate functionality into reusable components.

### Network Namespaces <a name="network-namespaces"></a>
Linux by default shares a single set of network interfaces and routing table entries, such that an
installed application can bind to all interfaces and has access to all other services currently
running on the system. Network namespaces implemented in the kernel provide a way to isolate
networks, interfaces and services from each other. This is the technology that docker uses to
isolate networking in docker apps from the host and other docker apps.

Network namespaces provide a way to have separate virtual interfaces and routing tables that operate
independent of each other. They can be manipulated via the `ip netns` command.

```bash
# Create a new network namespace
# ip netns add <namespace>
sudo ip netns add foo

# List network namespaces
ip netns list
```

Once a network namespace has been created you need to configure how/if it connects to the host. This
can be done by creating a pair of virtual Ethernet (***veth***) interfaces and assigning them to the
new network namespace as by default they will be assigned to the root namespace. The root namespace
or global namespace is the default namespace used by the host for regular networking.

```bash
# Create veth pair veth1 and veth2
sudo ip link add veth1 type veth peer name veth2

# Verify veth pair creation and view their relationship
# both are part of the root namespace by default
ip a
# veth1@veth2: <BROADCAST,MULTICAST,M-DOWN>
# veth2@veth1: <BROADCAST,MULTICAST,M-DOWN>

# Connect foo namespace to root namespace by assigning half the veth pair to the foo namespace
sudo ip link set veth2 netns foo

# Verify that the root namespace listing no longer shows veth2
# notice also that the relationship of veth1 has changed
ip a
# veth1@if4: <BROADCAST,MULTICAST>

# Verify that the foo namespace now owns veth2
sudo ip netns exec foo ip a
# lo: <LOOPBACK>
# veth2@if5: <BROADCAST,MULTICAST>

# Assign IPv4 address to the new veth pair
sudo ifconfig veth1 192.168.100.1/24 up
sudo ip netns exec foo ifconfig veth2 192.168.100.2/24 up

# Verify that the assigned ips took
ip a
# inet 192.168.100.1/24 brd 192.168.100.255 scope global veth1

sudo ip netns exec foo ip a
# inet 192.168.100.2/24 brd 192.168.100.255 scope global veth2

# Verify connectivity between veth pair
sudo ping 192.168.100.2
# 64 bytes from 192.168.100.2: icmp_seq=1 ttl=64 time=0.070 ms

sudo ip netns exec foo ping 192.168.100.1
# 64 bytes from 192.168.100.1: icmp_seq=1 ttl=64 time=0.080 ms
```

Now we have connectivity between our veth pair across network namespaces. Because the
***192.168.100.0/24*** network, that we configured the veth pair on, is a separate network from the
host any applications running within the new network namespace will not have connectivity to
anything else on your host or networks currently including external access to the internet.

```bash
# Prove out isolation
sudo ping www.google.com
# 64 bytes from -----.1e100.net (172.217.1.196): icmp_seq=1 ttl=56 time=13.3 ms

sudo ip netns exec foo ping www.google.com
# connect: Network is unreachable
```

In the following sub sections I'll show you how to automated this complicated setup using the
***Net*** ruby module.

#### TeamViewer Example <a name="teamviewer-example"></a>
In this example I'll be showing you how to isolate Teamviewer such that Teamviewer is only able to
bind to the veth IPv4 address that we create for it rather than all network interfaces on the host.
This will allow you to have a local Teamviewer instance running and accessible from your network
facing IP but also to be able to SSH port forward other Teamviewer instances to your veth addresses.

```bash
require_relative '../lib/nub/net'
require_relative '../lib/nub/user'
!puts("Must be root to execute") and exit if not User.root?

if ARGV.size > 0
  cmd = ARGV[0]
  app = ARGV[1]
  namespace = "foo"
  host_veth = Net::Veth.new("veth1", "192.168.100.1")
  guest_veth = Net::Veth.new("veth2", "192.168.100.2")
  network = Net::Network.new("192.168.100.0", "24")
  if cmd == "isolate"
    Net.create_namespace(namespace, host_veth, guest_veth, network, "enp+")
    Net.namespace_connectivity?(namespace, "google.com")
    Net.namespace_exec(namespace, "lxterminal")
  elsif cmd == "destroy"
    Net.delete_namespace(namespace, host_veth, network, "enp+")
  end
else
  puts("Isolate: #{$0} isolate <app>")
  puts("Destroy: #{$0} destroy")
end
```

#### PIA VPN Example <a name="pia-vpn-example"></a>
```ruby
WIP

Example1: Network namespace with access only to the 192.168.100.0 network which only has the
host address 192.168.100.1 available which only has access to the internet via the PIA VPN.

namespace = 'pia'
host_veth = Veth.new('veth1', '192.168.100.1')
guest_veth = Veth.new('veth2', '192.168.100.2')
network = Network.new('192.168.100.0', '24', ['209.222.18.222', '209.222.18.218'])
```

### Network Proxy <a name="network-proxy"></a>
The Net module provides simple access to the system proxy environment variables.

```ruby
Net.proxy.ftp
Net.proxy.http
Net.proxy.https
Net.proxy.no
Net.proxy.uri
Net.proxy.port

# Simple way to check if a proxy is set
Net.proxy?

# Bash compatible string to use to insert proxy into commands
Net.proxy_export
```

```bash
# Ping type equivalent that works behind a proxy
curl -m 3 -sL -w "%{http_code}" google.com -o /dev/null
```

## Pacman Module <a name="pacman-module"></a>

## Process Module <a name="process-module"></a>

## Sys Module <a name="sys-module"></a>

## ThreadComm Module <a name="threadcomm-module"></a>

## User Module <a name="user-module"></a>

```ruby
require 'nub'

# Check if the user is root
User.root?

# Drop root privileges to regular user that invoked sudo
User.drop_privileges

# Raise privileges back to sudo user if previously dropped
User.raise_privileges
```

## Ruby Gem Creation <a name="ruby-gem-creation"></a>
http://guides.rubygems.org/make-your-own-gem/

This is my first ruby gem and am documenting what I did here

### Package Layout <a name="package-layout"></a>
All the ruby code will be in the sub directory ***lib***

* ***lib*** is where your gem's actual code should reside
* ***nub.gemspec*** is your interface to RubyGems.org all the data provided here is used by the gem
repo

### Build Gem <a name="build-gem"></a>
```
gem build nub.gemspec
```

### Install Gem <a name="install-gem"></a>
```
gem install nub-0.0.1.gem
```

### Push Gem <a name="push-gem"></a>
Once you've built and tested your gem and are happy with it push it to RubyGems.org

```bash
# Download your user credentials
curl -u phR0ze https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
# Enter host password for user 'phR0ze':
# Revoke read permission from everyone but you
chmod og-r ~/.gem/credentials
# Push gem
gem push nub-0.0.1.gem
# List out your gems takes about a min
gem list -r nub
```

## Integrate with Travis-CI <a name="integrate-with-travis-ci"></a>
Example project https://github.com/Integralist/Sinderella

### Install Travis Client <a name="install-travis-client"></a>
```bash
sudo gem install travis --no-user-install
```

### Deploy Ruby Gem on Tag <a name="deploy-ruby-gem-on-tag"></a>
Create the file ***.travis.yml***

* Using ***cache: bundler*** builds the dependencies once and then reuses them in future builds.
* Script ***rake*** is actually the default for ***ruby*** but calling it out for clarity to run unit tests
* Deploying using the ***rubygems*** provider on tags

```yaml
language: ruby
sudo: false
cache: bundler
rvm:
  - 2.5.0
before_install:
  - gem update --system
script:
  - rake
deploy:
  provider: rubygems
  api_key:
    secure: <encrypted key>
  gem: nub
  on:
    tags: true
notifications:
  email: false
```

