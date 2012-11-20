# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.required_rubygems_version = '>= 1.3.6'

  # The following four lines are automatically updates by the "gemspec"
  # rake task. It it completely safe to edit them, but using the rake task
  # is easier.
  s.name              = 'merit'
  s.version           = '0.0.2'
  s.date              = '2012-11-20'
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

  s.add_dependency 'terminal-table'

  s.rdoc_options     = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[LICENSE README.md]

  # The manifest is created by the "gemspec" rake task. Do not edit it
  # directly; your changes will be wiped out when you next run the task.

  # = MANIFEST =
  s.files = %w[
    Gemfile
    Guardfile
    LICENSE
    README.md
    Rakefile
    examples/stub.rb
    examples/stub1.rb
    examples/stub2.rb
    examples/stub3.rb
    examples/stub4.rb
    lib/merit.rb
    lib/merit/bar_chart.rb
    lib/merit/errors.rb
    lib/merit/load_curve.rb
    lib/merit/load_profile.rb
    lib/merit/order.rb
    lib/merit/participants/participant.rb
    lib/merit/participants/producer.rb
    lib/merit/participants/types.rb
    lib/merit/participants/user.rb
    lib/merit/root.rb
    lib/merit/version.rb
    load_profiles/agriculture_chp.csv
    load_profiles/buildings_chp.csv
    load_profiles/industry_chp.csv
    load_profiles/solar_pv.csv
    load_profiles/total_demand.csv
    load_profiles/wind_coastal.csv
    load_profiles/wind_inland.csv
    load_profiles/wind_offshore.csv
    merit.gemspec
    output/chael.csv
    output/output.csv
  ]
  # = MANIFEST =

end
