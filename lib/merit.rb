# General libraries
require 'csv'
require 'terminal-table'
require 'forwardable'

# Merit order specific
require 'merit/root'
require 'merit/version'
require 'merit/area'
require 'merit/errors'

# Mixins
require 'merit/participants/profitable'

require 'merit/calculator'
require 'merit/order'
require 'merit/order_attribute_groups'
require 'merit/load_curve'
require 'merit/load_profile'

require 'merit/participant_set'

require 'merit/participants/participant'
require 'merit/participants/producer'
require 'merit/participants/types'
require 'merit/participants/supply_interconnect'
require 'merit/participants/user'
require 'merit/participants/user/total_consumption'
require 'merit/participants/user/with_curve'

# Helpers
require 'merit/bar_chart'
require 'merit/csv_writer'
require 'merit/collection_table'
