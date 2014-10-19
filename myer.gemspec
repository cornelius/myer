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
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','myer.rdoc']
  s.rdoc_options << '--title' << 'myer' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'myer'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('rspec')
  s.add_runtime_dependency('gli','2.12.2')
end
