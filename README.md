# ruby-nub
Collection of ruby utils I've used in several of my projects and wanted re-usable

[![Build Status](https://travis-ci.org/phR0ze/ruby-nub.svg)](https://travis-ci.org/phR0ze/ruby-nub)

## classes

### cmds
Command like syntax for Ruby command line parameters

## Ruby Gem Creation
http://guides.rubygems.org/make-your-own-gem/

This is my first ruby gem and am documenting what I did here

### Package Layout
All the ruby code will be in the sub directory ***lib***

### Build Gem
```
gem build cmds.gemspec
```

### Install Gem
```
sudo gem install --no-user-install cmds-0.0.1.gem
```

