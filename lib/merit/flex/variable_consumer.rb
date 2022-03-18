# frozen_string_literal: true

module Merit
  module Flex
    # A flexibility participant which can only consume, and whose input capacity may vary each hour
    # using an availability curve. This differs from other flexibility options where input capacity
    # and availability are fixed for the whole year.
    class VariableConsumer < Base
      def initialize(opts)
        if !opts[:availability] || opts[:availability].is_a?(Numeric)
          raise(
            ArgumentError,
            'availability curve must be an array of values, use Flex::Base if you wish ' \
            'to use a numeric availability'
          )
        end

        super(opts.merge(output_capacity_per_unit: 0.0))

        @availability    = CurveTools.availability_curve(opts[:availability])
        @output_capacity = calculate_capacity_curve(@output_capacity_per_unit)
        @input_capacity  = calculate_capacity_curve(@input_capacity_per_unit)
      end

      def unused_input_capacity_at(point)
        @input_capacity[point] + @load_curve.get(point)
      end

      def assign_excess(point, amount)
        input_cap = @input_capacity[point] + @load_curve.get(point)

        amount = input_cap if amount > input_cap
        @load_curve.set(point, @load_curve.get(point) - amount)

        amount
      end

      private

      # Unused. Provided only as a stub for the base class.
      def available_output_capacity
        0.0
      end

      # Unused. Provided only as a stub for the base class.
      def available_input_capacity
        0.0
      end

      def calculate_capacity_curve(value)
        total_capacity = value * number_of_units
        availability.map { |avail| avail * total_capacity }
      end
    end
  end
end
