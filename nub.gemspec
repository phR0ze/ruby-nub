Gem::Specification.new do |spec|
  spec.name        = 'nub'
  spec.version     = '0.0.49'
  spec.summary     = "Collection of useful utilities"
  spec.authors     = ["Patrick Crummett"]
  spec.homepage    = 'https://github.com/phR0ze/ruby-nub'
  spec.license     = 'MIT'
  spec.files       = `git ls-files | grep lib`.split("\n") + ['LICENSE', 'README.md']

  # Runtime dependencies
  spec.add_dependency('colorize', '~> 0.8.1')
  spec.add_dependency('minitest', '~> 5.11.3')
  spec.add_dependency('rake', '~> 12.0')

  # Development dependencies
  spec.add_development_dependency('coveralls', '~> 0.8')
  spec.add_development_dependency('bundler', '~> 1.16')
  spec.add_development_dependency('rake', '~> 12.0')
end
# vim: ft=ruby:ts=2:sw=2:sts=2
