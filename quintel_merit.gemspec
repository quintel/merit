# coding: utf-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'merit/version'

Gem::Specification.new do |s|
  s.name         = 'quintel_merit'
  s.version      = Merit::VERSION
  s.platform     = Gem::Platform::RUBY

  s.authors      = [ 'Anthony Williams',
                     'Chael Kruip',
                     'Dennis Schoenmakers' ]

  s.email        = [ 'anthony.williams@quintel.com',
                     'chael.kruip@quintel.com',
                     'dennis.schoenmakers@quintel.com' ]

  s.homepage      = 'http://github.com/quintel/merit'
  s.summary       = 'A merit order calculation library written in Ruby.'
  s.description   = ''

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(spec|features)/})
  s.require_paths = [ 'lib' ]

  s.add_development_dependency 'rake',  '>= 0.9.0'
  s.add_development_dependency 'rspec', '>= 2.11.0'

  s.add_dependency 'terminal-table'
end
