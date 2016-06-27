# General libraries
require 'csv'
require 'terminal-table'
require 'forwardable'

# Merit order specific
require_relative 'merit/version'
require_relative 'merit/errors'

# Mixins
require_relative 'merit/participants/profitable'

require_relative 'merit/calculator'
require_relative 'merit/cost_strategy'
require_relative 'merit/curve'
require_relative 'merit/order'
require_relative 'merit/order_attribute_groups'
require_relative 'merit/load_profile'
require_relative 'merit/price_curves'

require_relative 'merit/participant_set'

require_relative 'merit/participants/participant'
require_relative 'merit/participants/producer'
require_relative 'merit/participants/types'
require_relative 'merit/participants/supply_interconnect'
require_relative 'merit/participants/user'
require_relative 'merit/participants/user/total_consumption'
require_relative 'merit/participants/user/with_curve'

require_relative 'merit/flex/base'
require_relative 'merit/flex/black_hole'
require_relative 'merit/flex/reserve'
require_relative 'merit/flex/storage'

require_relative 'merit/lole'
require_relative 'merit/excess'

# Helpers
require_relative 'merit/bar_chart'
require_relative 'merit/csv_writer'
require_relative 'merit/collection_table'
require_relative 'merit/point_table'
