# cmds
Command like syntax for Ruby command line parameters

[![Build Status](https://travis-ci.org/phR0ze/cmds.svg)](https://travis-ci.org/phR0ze/cmds)

## Ruby Gem Creation
http://guides.rubygems.org/make-your-own-gem/
This is my first ruby gem and am documenting what I did here

### Package Layout
The Gem code will be in a directory called ***lib*** as a single file named the same thing as your
package i.e. ***cmds.rb***

### Build Gem
```
gem build cmds.gemspec
```

### Install Gem
```
sudo gem install --no-user-install cmds-0.0.1.gem
```

