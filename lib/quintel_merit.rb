# There is already a rubygem named Merit https://github.com/tute/merit
# So this code needs to have a different gem name. We have chosen quintel_merit.
# This file checks whether we are clashing with that existing gem and, if not
# loads the code.
if Kernel.const_defined?(:Merit)
  raise 'Merit class has already been defined; cannot load quintel_merit gem'
end

require 'merit'
