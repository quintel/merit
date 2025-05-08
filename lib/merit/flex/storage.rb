# frozen_string_literal: true

module Merit
  module Flex
    class Storage < Base
      # COSTS: revenue & fuel costs (per_mwh)

      attr_reader :reserve

      # Public: Creates a new Storage participant which may retain excess energy produced by
      # always-on producers so that it may be used later.
      def initialize(opts)
        super

        @input_efficiency  = opts[:input_efficiency]  || 1.0
        @output_efficiency = opts[:output_efficiency] || 1.0

        decay =
          (->(point, amount) { opts[:decay].call(point, amount) } if opts[:decay])

        @reserve = (opts[:reserve_class] || Reserve).new(
          opts.fetch(:volume_per_unit) * number_of_units * availability, &decay
        )
      end

      def unused_input_capacity_at(point)
        [@input_capacity + @load_curve.get(point), @reserve.unfilled_at(point)].min
      end

      def assign_excess(point, amount)
        return 0.0 if @load_curve.get(point).positive?

        input_cap = @input_capacity + @load_curve.get(point)

        amount  = amount > input_cap ? input_cap : amount
        amount *= @input_efficiency

        stored = @reserve.add(point, amount) / @input_efficiency

        @load_curve.set(point, @load_curve.get(point) - stored)

        stored
      end

      def max_load_at(point)
        # Don't discharge in the same hour as charging.
        return 0.0 if @load_curve.get(point).negative?

        in_reserve = @reserve.at(point) * @output_efficiency
        output_capacity_left = @output_capacity - @load_curve.get(point)

        in_reserve > output_capacity_left ? output_capacity_left : in_reserve
      end

      # Public: Assigns the load to the storage technology and retains the energy in the reserve for
      # future use.
      #
      # Returns the load.
      def set_load(point, amount)
        previous_load = load_at(point)

        super

        diff = amount - previous_load
        @reserve.take(point, diff / @output_efficiency) unless diff.zero?

        amount
      end
    end
  end
end
