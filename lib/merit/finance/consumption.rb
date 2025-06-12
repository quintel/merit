# frozen_string_literal: true

module Merit
  module Finance
    # This (mixin) module includes methods for User participants with respect to
    # fuel costs. To be injected into the graph after calculation.
    module Consumption
      def fuel_costs
        @fuel_costs ||= fuel_costs_curve.sum
      end

      def fuel_costs_curve
        @fuel_costs_curve ||= @load_curve * order.price_curve
      end
    end
  end
end
