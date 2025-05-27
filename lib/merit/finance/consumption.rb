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

      # TODO: remove because we need to divide with output later in engine
      def fuel_costs_per_mwh
        consumpition_mwh = @load_curve.sum(0.0).abs
        return if consumpition_mwh.zero?

        fuel_costs / consumpition_mwh
      end
    end
  end
end
