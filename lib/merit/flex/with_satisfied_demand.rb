# frozen_string_literal: true

module Merit
  module Flex
    # Flex participant with demand partially satisfied by a given satisfied_demand_curve
    # A curve with negative values represents satisfied input
    class WithSatisfiedDemand < Base
      def initialize(opts)
        super

        @load_curve = Curve.new(opts[:satisfied_demand_curve])
      end
    end
  end
end
