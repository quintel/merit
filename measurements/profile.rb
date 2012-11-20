# This is a simple profiler which loads the merit library, and calculates the
# default example stub ten times. The stub is calculated ten times instead of
# one so as to give the profiler enough time to gather data.
#
# The script accepts a single argument which will be used as the name for the
# profiling data and PDF; supply this is you want to create a new profile for
# comparison with a previous run. No argument will just use "profile".
#
# The output PDF is saved to measurements/ and opened automatically.

ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
$LOAD_PATH.push(ROOT + '/lib')

require 'merit'
require 'perftools'
require 'fileutils'
require_relative '../examples/stub'

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

puts "Finished profiling in #{ Time.now - started } seconds."

# Don't generate the profiling output if the user doesn't want it.
exit if name == '-'

system "pprof.rb --pdf measurements/#{ name } > measurements/#{ name }.pdf"
system "open measurements/#{ name }.pdf"

%W( #{ name } #{ name }.symbols ).each do |artifact|
  path = ROOT + "/measurements/#{ artifact }"
  FileUtils.rm(path) if File.exist?(path)
end
