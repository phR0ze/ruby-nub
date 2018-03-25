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

## Classes <a name="classes"></a>
Different classes provided with the gem are explained below

### Commander <a name="commander"></a>
Commander was created mainly because all available options parsers seemed complicated and overweight
and partly because I enjoyed understanding every bit going into it. Commands offers ***git*** like
command syntax that is becoming so popular. Personally I like the syntax as it feels cleaner and
faster to type.

There are two kinds of options available for use, ***positional*** and ***named***. Options are any
non command parameters that come after a command. Commands may be chained together sequentially
either with their own independent options (i.e. options between the commands) or sharing the next
command's options. ***Postitional*** options get their position from the order in which they are
added to your command during configuration. Only positional options are taken into account for
order. Positional options are identified by the absence of preceding dashes.

Thus you have the ability to form expressions as follows:
```bash
# Single command with no options
./app list
# Command with a positional option
./app clean all
# Command with a positional option and a named option
./app clean all --minus=iso
# Chained commands sharing all command options to the right of the next command
# thus the 'clean' and 'build' commands share the 'all' positional option
./app clean build all
# Multiple commands run sequentially with positional options per command
# thus the 'clean' and 'build' commands each have their own positional arguments
./app clean all build all
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

Help would look something like:
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

