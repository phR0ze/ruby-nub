# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub&branch=master)
[![Gem Version](https://badge.fury.io/rb/nub.svg)](https://badge.fury.io/rb/nub)
[![Coverage Status](https://coveralls.io/repos/github/phR0ze/ruby-nub/badge.svg?branch=master)](https://coveralls.io/github/phR0ze/ruby-nub?branch=master)
[![Dependency Status](https://beta.gemnasium.com/badges/github.com/phR0ze/ruby-nub.svg)](https://beta.gemnasium.com/projects/github.com/phR0ze/ruby-nub)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

### Table of Contents
* [Deploy](#deploy)
* [Commander](#commander)
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
* [Config](#config)
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

## Commander <a name="commander"></a>
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

## Config <a name="config"></a>
Config is a simple YAML wrapper with some extra features. Since it implements the ***Singleton***
pattern you can easily use it through out your app without carrying around instances everywhere.
It creates config files in memory and saves them to the config ***~/.config*** directory when saved
unless the given config exists along side the app's path. If the config file already exists it simply reads it.

Initialize once on entry of your app and leverage throughout:
```ruby
Config.init("openvpn.yml")
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

