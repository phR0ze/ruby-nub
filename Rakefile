task :default => :build

# Need to test log separately as it is a singleton
task :build do
  if ENV['TRAVIS']
    require 'coveralls'
    Coveralls.wear!
  end
  exit(1) if not system("./test/test.rb -p")
  exit(1) if not system("./test/test_log.rb -p")
end

# vim: ft=ruby:ts=2:sw=2:sts=2
