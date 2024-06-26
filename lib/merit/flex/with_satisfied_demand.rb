# frozen_string_literal: true

module Merit
  module Flex
    # Flex participant with demand partially satisfied by a given satisfied_demand_curve.
    # The direct satisfied demand is not price setting.
    # Optionally, takes a constraint lambda.
    #
    # A curve with negative values represents satisfied input.
    class WithSatisfiedDemand < Base
      def initialize(opts)
        super

        @constraint = opts[:constraint] || ->(_, a) { a }
        @load_curve = Curve.new(opts[:satisfied_demand_curve])
        @price_setting = Array.new(8760, false)
      end

      def price_setting?(point)
        @price_setting[point]
      end

      def assign_excess(point, amount)
        input_cap = @input_capacity + @load_curve.get(point)
        amount = [amount, input_cap].min
        amount = @constraint.call(point, amount)

        @load_curve.set(point, @load_curve.get(point) - amount)

        @price_setting[point] = true unless amount.zero?

        amount
      end
    end
  end
end
