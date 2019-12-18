# frozen_string_literal: true

module Merit
  module Flex
    # Eager storage will fill its buffer each hour (constrainted by input
    # capacity), even taking energy from dispatchables if necessary.
    #
    # It behaves unlike normal storage in that it does not optionally take
    # excess energy from must-runs, but instead creates a demand which must be
    # met by the calculator. It assumes that it will receive the energy needed,
    # automatically filling when `load_at` is called.
    class EagerStorage < Storage
      attr_reader :input_curve, :output_curve

      def initialize(*)
        super

        @last_filled = -1

        # The amount of energy with which we'll try to fill the buffer in each
        # point.
        @fill_amount = @input_capacity * @input_efficiency

        # @did_fill = Array.new(8760)

        @input_curve = Array.new(8760, 0.0)
        @output_curve = Array.new(8760, 0.0)
      end

      # Public: Returns the amount of energy which can be discharged from the
      # reserve in the given point and consumed by a User.
      #
      # Returns a Float.
      def load_at(point)
        amount =
          if @last_filled < point
            fill_buffer!(point)
          elsif point.zero?
            @reserve.at(0)
          else
            amount = @reserve.at(point) - @reserve.at(point - 1)
            amount.negative? ? 0.0 : amount
          end

        @input_curve[point] = amount / @input_efficiency
      end

      def set_load(point, amount)
        return amount if amount.zero?

        @load_curve[point] += amount
        @reserve.take(point, amount / @output_efficiency)

        @output_curve[point] = amount
      end

      def production(unit = :mj)
        if unit == :mj
          @input_curve.sum * 3600
        elsif unit == :mwh
          @input_curve.sum
        else
          raise "Unknown unit: #{unit}"
        end
      end

      # Public: Eager storage never takes excess; it has an explicit demand
      # which is always met.
      def assign_excess(_point, _amount)
        0.0
      end

      def user?
        true
      end

      private

      def fill_buffer!(point)
        # Reserve won't overfill.
        stored = @reserve.add(point, @fill_amount)

        @load_curve.set(
          point,
          @load_curve.get(point) - stored / @input_efficiency
        )

        @last_filled = point

        stored
      end
    end
  end
end
