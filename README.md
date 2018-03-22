# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub)
[![Gem Version](https://badge.fury.io/rb/nub.svg)](https://badge.fury.io/rb/nub)

### Table of Contents
* [Classes](#classes)
    * [cmds](#cmds)
* [Ruby Gem Creation](#ruby-gem-creation)
    * [Package Layout](#package-layout)
    * [Build Gem](#build-gem)
    * [Install Gem](#install-gem)
    * [Push Gem](#push-gem)
 
## Classes <a name="classes"></a>
Different classes provided with the gem are explained below

### cmds <a name="cmds"></a>
Command like syntax for Ruby command line parameters

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

