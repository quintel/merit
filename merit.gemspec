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

  s.homepage     = 'http://github.com/quintel/merit'
  s.summary      = 'A merit order calculation library written in Ruby.'
  s.description  = ''

  s.require_path = 'lib'

  s.add_development_dependency 'rake',  '>= 0.9.0'
  s.add_development_dependency 'rspec', '>= 2.11.0'

  s.rdoc_options     = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[LICENSE README.md]

  # The manifest is created by the "gemspec" rake task. Do not edit it
  # directly; your changes will be wiped out when you next run the task.

  # = MANIFEST =
  s.files = `git ls-files`.split($/)
  s.test_files = s.files.select { |path| path =~ /^spec\/.*\.rb/ }
end
