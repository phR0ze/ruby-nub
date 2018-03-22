# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub)

### Table of Contents
* [Classes](#classes)
    * [cmds](#cmds)
* [Ruby Gem Creation](#ruby-gem-creation)
    * [Package Layout](#package-layout)
    * [Build Gem](#build-gem)
    * [Install Gem](#install-gem)
 
## Classes <a name="classes"></a>
Different classes provided with the gem are explained below

### cmds <a name="cmds"></a>
Command like syntax for Ruby command line parameters

## Ruby Gem Creation <a name="ruby-gem-creation"></a>
http://guides.rubygems.org/make-your-own-gem/

This is my first ruby gem and am documenting what I did here

### Package Layout <a name="package-layout"></a>
All the ruby code will be in the sub directory ***lib***

### Build Gem <a name="build-gem"></a>
```
gem build cmds.gemspec
```

### Install Gem <a name="install-gem"></a>
```
sudo gem install --no-user-install cmds-0.0.1.gem
```

