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
  task :excess do
    merit_order = Merit.stub
    merit_order.add(Merit::CurveProducer.new(
      key: :curve_producer,
      marginal_costs: 0.0,
      load_curve: [8_000.0] * 8760
    ))
    5.times do |i|
      merit_order.add(Merit::Flex::Storage.new(
        key: :"storage_#{i}",
        marginal_costs: i < 2 ? 15.0 : i,
        output_capacity_per_unit: 500.0,
        number_of_units: 1.0,
        availability: 1.0,
        volume_per_unit: 25000.0
      ))
    end
    merit_order.add(Merit::Flex::Base.new(
      key: :dump,
      marginal_costs: :null,
      input_capacity_per_unit: 50000.0,
      output_capacity_per_unit: 50000.0,
      number_of_units: 1.0,
      availability: 1.0
    ))
    puts Benchmark.realtime { merit_order.calculate }
  end
  task :reserve do
    require 'benchmark/ips'

    Benchmark.ips do |x|
      x.report('SimpleReserve without decay') do
        reserve = Merit::Flex::SimpleReserve.new(10)

        8760.times do |frame|
          (frame % 2).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
        end
      end

      x.report('SimpleReserve with decay') do
        reserve = Merit::Flex::SimpleReserve.new(10) { |val| val * 0.1 }

        8760.times do |frame|
          (frame % 2).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
        end
      end

      x.report('SimpleReserve without decay, every 4th hour') do
        reserve = Merit::Flex::SimpleReserve.new(10)

        8760.times do |frame|
          if (frame % 4).zero?
            (frame % 8).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
          end
        end
      end

      x.report('SimpleReserve with decay, every 4th hour') do
        reserve = Merit::Flex::SimpleReserve.new(10) { |val| val * 0.1 }

        8760.times do |frame|
          if (frame % 4).zero?
            (frame % 8).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
          end
        end
      end

      x.report('Reserve without decay') do
        reserve = Merit::Flex::Reserve.new(10)

        8760.times do |frame|
          (frame % 2).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
        end
      end

      x.report('Reserve with decay') do
        reserve = Merit::Flex::Reserve.new(10) { |val| val * 0.1 }

        8760.times do |frame|
          (frame % 2).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
        end
      end

      x.report('Reserve without decay, every 4th hour') do
        reserve = Merit::Flex::Reserve.new(10)

        8760.times do |frame|
          if (frame % 4).zero?
            (frame % 8).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
          end
        end
      end

      x.report('Reserve with decay, every 4th hour') do
        reserve = Merit::Flex::Reserve.new(10) { |val| val * 0.1 }

        8760.times do |frame|
          if (frame % 4).zero?
            (frame % 8).zero? ? reserve.add(frame, 5) : reserve.take(frame, 5)
          end
        end
      end
    end
  end
end

task :profile do
  # This is a simple profiler which loads the merit library, and calculates the
  # default example stub ten times. The stub is calculated ten times instead of
  # one so as to give the profiler enough time to gather data.
  #
  # The script accepts a single argument which will be used as the name for the
  # profiling data and PDF; supply this is you want to create a new profile for
  # comparison with a previous run. No argument will just use "profile".
  #
  # The output PDF is saved to measurements/ and opened automatically.
  #
  # To run this script, first install the additional dependencies:
  #
  #   $ gem install perftools.rb term-ansicolor
  #
  # It can be run with the following arguments:
  #
  #   $ ruby measurements/profile.rb [PROFILE_NAME] [ITERATIONS]
  #
  # PROFILE_NAME is an optional name to which the profile results are saved, and
  # will also be used to name the PDF. Supply a different name with each run if
  # you want to compare results. Supplying "-" will skip creation of the PDF and
  # simply outputs the runtime information.
  #
  # ITERATIONS, which defaults to 10, controls how many times to calculate the
  # stub merit order.

  ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
  $LOAD_PATH.push(ROOT + '/lib')

  require 'merit'
  require 'perftools'
  require 'term/ansicolor'
  require 'fileutils'
  require_relative 'examples/stub'

  if (name = ARGV[0] || 'profile').match(/\.|\s/)
    raise 'No "." or spaces are allowed in the profile name.'
  end

  # Put any initial startup code which you don't want profiling here:
  Merit::LoadProfile.reader = Merit::LoadProfile::CachingReader.new

  puts 'Beginning profiling...'

  iterations = (ARGV[1] || 10).to_i
  started    = Time.now

  PerfTools::CpuProfiler.start("measurements/#{ name }") do
    iterations.times { Merit.stub.calculate }
  end

  duration = Time.now - started

  include Term::ANSIColor
  print green, "Finished profiling #{ iterations } calculations in ",
        underline, "#{ duration.round(4) } seconds", reset, green,
        " (", underline, "#{ ((duration / iterations) * 1000).round(2) } ms",
        reset, green, " per calculation).", reset, "\n"

  # Don't generate the profiling output if the user doesn't want it.
  exit if name == '-'

  system "pprof.rb --pdf measurements/#{ name } > measurements/#{ name }.pdf"
  system "open measurements/#{ name }.pdf"

  %W( #{ name } #{ name }.symbols ).each do |artifact|
    path = ROOT + "/measurements/#{ artifact }"
    FileUtils.rm(path) if File.exist?(path)
  end
end
