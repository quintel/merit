# frozen_string_literal: true

require 'spec_helper'
require_relative 'decaying_reserve_examples'
require_relative 'non_decaying_reserve_examples'

module Merit
  RSpec.describe Flex::SimpleReserve do
    include_examples 'non-decaying reserve'
    include_examples 'decaying reserve'
  end
end
