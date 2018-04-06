# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub)
[![Gem Version](https://badge.fury.io/rb/nub.svg)](https://badge.fury.io/rb/nub)
[![Coverage Status](https://coveralls.io/repos/github/phR0ze/ruby-nub/badge.svg?branch=master)](https://coveralls.io/github/phR0ze/ruby-nub?branch=master)
[![Dependency Status](https://beta.gemnasium.com/badges/github.com/phR0ze/ruby-nub.svg)](https://beta.gemnasium.com/projects/github.com/phR0ze/ruby-nub)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

### Table of Contents
* [Deploy](#deploy)
* [Commander](#commander)
    * [Commands](#commands)
    * [Options](#options)
    * [Help](#help)
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
Commander was created mainly because all available options parsers seemed complicated and overweight
and partly because I enjoyed understanding every bit going into it. Commander offers ***git*** like
command syntax that is becoming so popular. Personally I like the syntax as it feels cleaner and
faster to type.

There are two kinds of paramaters that commander deals with ***commands*** and ***options***.
Commands are specific named parameters that may or may not have options specific to it. Commands
have their own help to display their usage and available options.

### Commands <a name="commands"></a>
Commands are defined via configuration as key words that trigger different branches of functionality
for the application. Each command may have zero or more options that modify how this behaveior is
invoked. Whenever more than one command is used in the command line expression the expression is
interpreted as being a ***chained command expression***. Chained command expressions are executed
left to right, such that you can execute the ***clean*** command then the ***build*** command or
more in a single command line expression. Each command in a chained command expression may have its
own specific options (those coming after the command but before the next command) or if options are
omitted the required options from the next command will be used. The chained command options syntax
allows one to have a cleaner multi-command line expression with reusable options. Options are said
to apply in a chained command syntax when they are of the same type in the positional case or same
type and name in the named case.

***Global*** options are options that are added with the command ***add_global*** and will show up
set in the commands results using the ***:global*** symbol.

***Commander.new*** must be run from the app's executable file for it to pick up the app's filename
properly.

Example ruby configuration:
```ruby
if __FILE__ == $0
  examples = "Clean all: sudo ./#{app} clean all\n".colorize(:green)

  # Creates a new instance of commander
  cmdr = Commander.new(examples:examples)

  # Add global options
  cmdr.add_global([
    Option.new('-d|--debug', 'Debug output')
  ])

  # Create two commands with a chainable positional option
  cmdr.add('clean', 'Clean build', options:[
    Option.new(nil, 'Clean given components', allowed:['all', 'iso'])
  ])
  cmdr.add('build', 'Build components', options:[
    Option.new(nil, 'Build given components')
  ])
  cmdr.parse!

  debug = cmdr[:global][:debug]
  clean(cmdr[:clean][:clean0], debug:debug) if cmdr[:clean]
  build(cmdr[:build][:build0], debug:debug) if cmdr[:build]
end
```

Example command line expressions:
```bash
# Chained commands 'clean' and 'build' share the 'all' positional option, thus 'clean' will be
# executed first with the 'all' option then 'build' will be executed second with the 'all' option.
./app clean build all
# Chained commands 'clean' and 'build' with their own specific 'all' positional option which is
# exactly equivalent to the previous usage
./app clean all build all
```

### Options <a name="options"></a>
There are two kinds of options available for use, ***positional*** and ***named***. Positional
options are identified by the absence of preceding dash/dashes and interpreted according to the
order in which they were found. Positional options are a value being passed into the application.
Named options have a name that is prefixed with a dash (short hand) or two dashes (long hand) e.g.
***-h*** or ***--help*** and may simply be a flag or pass in a value. Option values require a
***type*** so that Commander can interpret how to use them. The supported value types are
***Flag, Integer, String, Array***. Values may be checked or not checked via the ***allowed***
config param. Positional options default to type String while named options default to type Flag.
Positional options are named internally with the command concatted with a an int for order ***e.g.
clean0*** zero based. Positional params are always required.

**Long Hand** form is always required for named options, short hand may or may not be given.

**Values** are indicated by the hint given e.g. ***-s|--skip=COMPONENTS*** indicates there is an
incoming value/values to be expected because of the hint ***COMPONENTS***.

Example ruby configuration:
```ruby
# Creates a new instance of commander with app settings as given
cmdr = Commander.new('app-name', 'app-version', 'examples')
# Create command with a positional argument
cmdr.add('clean', 'Clean build', options:[
  Option.new(nil, 'Clean given components', allowed:['all', 'iso', 'image']),,,,
  Option.new('-d|--debug', 'Debug mode'),
  Option.new('-s|--skip=COMPONENT', 'Skip the given components', allowed:['iso', 'image'], type:String)
])
# Create command with a single positional option with an allowed check for value
cmdr.add('build', 'Build components', options:[
  Option.new(nil, 'Build given components', allowed:['all', 'iso', 'image'])
])
cmdr.parse!
```

Example command line expressions:
```bash
# The parameter 'all' coming after the command 'clean' is a positional option with a default type of
# String that is checked against the optional 'allowed' values configuration
./app clean all
# The parameter '-d' coming after the command 'clean' is a named option using short hand form with
# an input type defaulted to Flag (i.e. a simple flag)
./app clean -d
# The parameter '--debug' coming after the command 'clean' is a named option using long hand form with
# an input type defaulted to Flag (i.e. a simple flag); exactly equivalent to the former expression
./app clean --debug
# The parameter '-s' coming after the command 'clean' is a named option using short hand form with
# an input value 'iso' of type String
./app clean -s iso
# The parameter '--skip' coming after the command 'clean' is a named option using long hand form
# with an input value 'iso' of type String; exactly equivalent to the former expression
./app clean --skip=iso
```

### Help <a name="help"></a>
Help for your appliation and commands is automatically supported with the ***-h*** and ***--help***
flags and is generated from the app ***name***, ***version***, ***examples***, ***commands***,
***descriptions*** and ***options*** given in Commander's configuration. Examples is just a free
form string that is displayed before usage so user's have an idea of how to put together the
commands and options. Allowed checks are added to the end of option descriptions in parenthesis.
Type and required indicators are added after allowed check descriptions.

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

**Required**
Options can be required using the ***required:true*** options param

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

