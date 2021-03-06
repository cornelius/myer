# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','myer','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'myer'
  s.version = Myer::VERSION
  s.author = 'Cornelius Schumacher'
  s.email = 'schumacher@kde.org'
  s.homepage = 'https://github.com/cornelius/myer'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Command line client for Project MySelf'
  s.license = 'MIT'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'myer'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('rspec')
  s.add_development_dependency('webmock')
  s.add_development_dependency('given_filesystem')
  s.add_development_dependency('codeclimate-test-reporter')
  s.add_runtime_dependency('gli','2.12.2')
  s.add_runtime_dependency('xdg')
end
