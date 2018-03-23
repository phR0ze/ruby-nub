Gem::Specification.new do |spec|
  spec.name        = 'nub'
  spec.version     = '0.0.24'
  spec.summary     = "Collection of useful utilities"
  spec.authors     = ["Patrick Crummett"]
  spec.homepage    = 'https://github.com/phR0ze/ruby-nub'
  spec.license     = 'MIT'
  spec.files       = `git ls-files | grep lib`.split("\n")

  # Runtime dependencies
  spec.add_dependency('colorize', '>= 0.8.1')
  spec.add_dependency('minitest', '>= 5.11.3')
  spec.add_dependency('rake')

  # Development dependencies
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rake')
end
# vim: ft=ruby:ts=2:sw=2:sts=2
