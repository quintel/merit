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

  desc 'Open a pry or irb session with a stub'
  task :stub do
    require 'pry'
    require_relative 'lib/merit/examples'

    print 'Loading stub data...'
    order = Merit::Examples.load('examples/much-flex.yml.gz')
    order.calculate
    puts ' done.'

    # rubocop:disable Lint/Debugger
    binding.pry
    # rubocop:enable Lint/Debugger
  end
end

desc 'Open a pry or irb session preloaded with Merit'
task console: ['console:run']

# Performance ----------------------------------------------------------------

namespace :performance do
  require 'benchmark'
  require 'merit'
  require 'time'
  require_relative 'lib/merit/examples'

  # Loads and runs a scenario, outputing benchmark and profile data
  #
  # For example:
  #   $ be rake performance:profile PROFILE=true ITERATIONS=10 FILE=examples/much-flex.yml.gz
  task :profile do
    # Put any initial startup code which you don't want profiling here:
    Merit::Curve.reader = Merit::Curve::CachingReader.new

    iterations = (ENV['ITERATIONS'] || 10).to_i
    path = ENV['FILE']

    if path.nil? || path.empty?
      raise 'You must supply a FILE=path to set up the scenario to be profiled'
    end

    print 'Loading stub data... '
    stub = Merit::Examples.read(path)
    puts 'done'

    # Warm up.
    Merit::Examples.build(stub).calculate

    if iterations.positive?
      print "#{iterations} iterations in ... "
      time = Benchmark.realtime { iterations.times { Merit::Examples.build(stub).calculate } }
      puts("#{time}s")
    end

    unless %w[0 no false off].include?(ENV['PROFILE'])
      require 'ruby-prof'
      print 'Profiling one run... '

      order = Merit::Examples.build(stub)
      GC.disable

      RubyProf.measure_mode = RubyProf::ALLOCATIONS
      RubyProf.start

      order.calculate
      result = RubyProf.stop

      printer = RubyProf::GraphHtmlPrinter.new(result)
      profile_name = "measurements/#{Time.now.strftime('%Y-%h-%m-%H%M-%S')}.html"
      File.open(profile_name, 'w') do |file|
        printer.print(file, min_percent: 0)
      end

      puts "saved to ./#{profile_name}"

      GC.enable
    end
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
