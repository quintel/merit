# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.required_rubygems_version = '>= 1.3.6'

  # The following four lines are automatically updates by the "gemspec"
  # rake task. It it completely safe to edit them, but using the rake task
  # is easier.
  s.name              = 'merit'
  s.version           = '0.0.1'
  s.date              = '2012-10-26'
  s.rubyforge_project = 'merit-graph'

  # You may safely edit the section below.

  s.platform     = Gem::Platform::RUBY

  s.authors      = [ 'Anthony Williams',
                     'Dennis Schoenmakers',
                     'Paolo Zaccagnini',
                     'Sebastian Burkhard' ]

  s.email        = [ 'hi@antw.me',
                     'dennis.schoenmakers@quintel.com',
                     'paolo.zaccagnini@quintel.com',
                     'sebastian.burkhard@quintel.com' ]

  s.homepage     = 'http://github.com/antw/turbine'
  s.summary      = 'An in-memory graph database written in Ruby.'
  s.description  = 'An experiment in graph databases, with Ruby...'

  s.require_path = 'lib'

  s.add_development_dependency 'rake',  '>= 0.9.0'
  s.add_development_dependency 'rspec', '>= 2.11.0'

  s.rdoc_options     = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[LICENSE README.md]

  # The manifest is created by the "gemspec" rake task. Do not edit it
  # directly; your changes will be wiped out when you next run the task.

  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    Guardfile
    LICENSE
    README.md
    Rakefile
    examples/energy.rb
    examples/family.rb
    lib/.DS_Store
    lib/merit.rb
    lib/merit/.DS_Store
    lib/merit/calculator.rb
    lib/merit/load_curve.rb
    lib/merit/load_curve_point.rb
    lib/merit/plant.rb
    lib/merit/version.rb
    merit.gemspec
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^spec\/.*\.rb/ }
end
