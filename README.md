# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub)
[![Gem Version](https://badge.fury.io/rb/nub.svg)](https://badge.fury.io/rb/nub)
[![Coverage Status](https://coveralls.io/repos/github/phR0ze/ruby-nub/badge.svg?branch=master)](https://coveralls.io/github/phR0ze/ruby-nub?branch=master)
[![Dependency Status](https://beta.gemnasium.com/badges/github.com/phR0ze/ruby-nub.svg)](https://beta.gemnasium.com/projects/github.com/phR0ze/ruby-nub)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

### Table of Contents
* [Deploy](#deploy)
* [Classes](#classes)
    * [Commander](#commander)
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
omitted those options that apply from the next command will be used. The chained command options
syntax allows one to have a cleaner multi-command line expression with reusable options. Options are
said to apply in a chained command syntax when they are of the same type in the positional case or
same type and name in the named case.

Example ruby configuration:
```ruby
# Creates a new instance of commander with app settings as given
cmdr = Commander.new('app-name', 'app-version', 'examples')
# Create two commands with a chainable positional option
cmdr.add('clean', 'Clean build', [
  Option.new(nil, 'Clean given components')
])
cmdr.add('build', 'Build components', [
  Option.new(nil, 'Build given components')
])
cmdr.parse!
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

### Positional vs Named options <a name="positional-vs-named-options"></a>
There are two kinds of options available for use, ***positional*** and ***named***. Positional
options are identified by the absence of preceding dash/dashes and interpreted according to the
order in which they were found. Positional options are a value being passed into the application.
Named options have a name that is prefixed with a dash (short hand) or two dashes (long hand) e.g.
***-h*** or ***--help*** and may simply be a bool flag or pass in a value. Option values require a
***type*** so that commander can interpret how to use them. The supported value types are
***Bool|String|Array***. Values may be checked or not checked via the ***allowed*** config param.
Positional options default to type String while named options default to type Bool.

Example ruby configuration:
```ruby
# Creates a new instance of commander with app settings as given
cmdr = Commander.new('app-name', 'app-version', 'examples')
# Create command with a positional argument
cmdr.add('clean', 'Clean build', [
  Option.new(nil, 'Clean given components', allowed=['all', 'iso', 'image'])
  Option.new('-d|--debug', 'Debug mode')
  Option.new('-s|--skip=COMPONENT', 'Skip the given components', allowed=['iso', 'image'])
])
# Create command with a single positional option with an allowed check for value
cmdr.add('build', 'Build components', [
  Option.new(nil, 'Build given components', allowed=['all', 'iso', 'image'])
])
cmdr.parse!
```

Example command line expressions:
```bash
# The parameter 'all' coming after the command 'clean' is a positional option with a default type of
# String that is checked against the optional 'allowed' values configuration
./app clean all
# The parameter '-s' coming after the command 'clean' is a named option
./app clean -m
# The parameter '--min' coming after the command 'clean' is a named option and is exactly equivalent
# to the former expression just using the long hand form
./app clean --min
# The parameter '-m' coming after the command 'clean' is a named option
./app clean -m
```

### Command help
-h and --help are automatically supported by all commands

### Global vs Command vs Chained options
Options may affect change at the global level or for a specific command or may affect one or more
commands if the commands are chained. Options used to the left of all commands are interpreted at
the global level. Options used after a command affect change for that command. Commands that are
chained (i.e. have no options separating them) and have options after the last command will apply
all options that apply to the given commands. 

Thus you have the ability to form expressions as follows:
```bash
# Single command with no options
./app list
# Command with a positional option
./app clean all
# Command with a positional option and a named option
./app clean all --minus=iso
```

Ruby syntax to configure this behavior would look like:
```ruby
# Creates a new instance of commander with app settings as given
cmdr = Commander.new('app-name', 'app-version', 'examples')
# Create a new command with out any options
cmdr.add('list', 'List build', [])
# Create a new command with positional and named options
cmdr.add('clean', 'Clean build', [
  CmdOpt.new(nil, 'Clean given components [all|iso|image]')
  CmdOpt.new('--minus=COMPONENT', 'Clean all except COMPONENT')
])
cmdr.add('build', 'Build components', [
  CmdOpt.new(nil, 'Build given components [all|iso|image]')
])
cmdr.parse!
```

App help would look something like:
```bash
app_v0.0.1
--------------------------------------------------------------------------------
Examples:
Clean build all: ./app clean build all

Usage: ./app [commands] [options]
    -h, --help                       Print command/options help
COMMANDS:
    list                             List out components
    clean                            Clean ISO components
    build                            Build ISO components

see './app COMMAND --help' for specific command help
```

Command help would look something like:
```bash
app_v0.0.1
--------------------------------------------------------------------------------
Usage: ./app clean [options]
    -h, --help                       Print command/options help
COMMANDS:
    list                             List out components
    clean                            Clean ISO components
    build                            Build ISO components

see './app COMMAND --help' for specific command help
```

**Required**
Options can be required using the ***required:true*** options param

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

