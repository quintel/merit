# frozen_string_literal: true

module Merit
  module Flex
    # Flex participant with demand partially satisfied by a given satisfied_demand_curve.
    # The direct satisfied demand is not price setting.
    #
    # A curve with negative values represents satisfied input.
    class WithSatisfiedDemand < Base
      def initialize(opts)
        super

        @load_curve = Curve.new(opts[:satisfied_demand_curve])
        @price_setting = Array.new(8760, false)
      end

      def price_setting?(point)
        @price_setting[point]
      end

      def assign_excess(point, amount)
        assigned = super

        @price_setting[point] = true unless assigned.zero?

        assigned
      end
    end
  end
end
