# frozen_string_literal: true

module Merit
  module Finance
    # This (mixin) module includes base methods for Flex participants with respect to
    # fuel costs and revenue. To be injected into the graph after calculation.
    module Flex
      include Base

      # Public: Returns the absolute amount of fuel costs of electricity in EUR.
      def fuel_costs
        @fuel_costs ||=
          if number_of_units.zero? || input_capacity_per_unit.zero?
            0.0
          else
            fuel_costs_curve.sum
          end
      end

      # Public: Returns the price curve for fuel costs. This is represented
      # by the negative values in the load price curve.
      def fuel_costs_curve
        @fuel_costs_curve ||= load_price_curve.clip_negative
      end

      # Public: Returns the price curve for revenue. This is represented
      # by the positive values in the load price curve.
      def revenue_curve
        @revenue_curve ||= load_price_curve.clip_positive
      end

      # Public: Returns the load price curve. For flex participants this curve
      # will contain positive and negative price values representing revenue and
      # fule costs
      def load_price_curve
        @load_price_curve ||= load_curve * order.price_curve
      end
    end
  end
end
