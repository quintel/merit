require 'bundler/gem_tasks'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'merit/version'

# Coverage -------------------------------------------------------------------

task :coverage do
  ENV['COVERAGE'] = 'true'
  exec 'bundle exec rspec'
end

# Documentation --------------------------------------------------------------

begin
  require 'yard'
  require 'yard-tomdoc'
  YARD::Rake::YardocTask.new do |doc|
    doc.options << '--no-highlight'
  end
rescue LoadError
  desc 'yard task requires that the yard gem is installed'
  task :yard do
    abort 'YARD is not available. In order to run yard, you must: gem ' \
          'install yard'
  end
end

# Console --------------------------------------------------------------------

namespace :console do
  task :run do
    command = system("which pry > /dev/null 2>&1") ? 'pry' : 'irb'
    exec "#{ command } -I./lib -r./lib/merit.rb"
  end

  desc 'Open a pry or irb session with a stub graph on `Merit.stub`'
  task :stub do
    command = system("which pry > /dev/null 2>&1") ? 'pry' : 'irb'
    exec "#{ command } -I./lib -r./lib/merit.rb -r./examples/stub.rb" \
         " -e 'puts(\"Please hold on while running mo.calculate...\");" \
         "mo = merit_order = Merit.stub; mo.calculate'" \
  end
end

desc 'Open a pry or irb session preloaded with Merit'
task console: ['console:run']

# Performance ----------------------------------------------------------------

namespace :performance do
  require 'benchmark'
  require 'merit'
  require './examples/stub'
  desc 'Run performance metrics for financial calculations on producers'
  task :loads do
    merit_order = Merit.stub
    puts Benchmark.realtime { merit_order.calculate }
  end
  task :profit do
    merit_order = Merit.stub
    merit_order.calculate
    puts Benchmark.realtime { merit_order.producers.map(&:profit) }
  end
end
