# frozen_string_literal: true

module Merit
  # Helper module for classes which need to calculate the net load of a merit order.
  module NetLoadHelper
    def initialize(order, excludes = [])
      @order    = order
      @excludes = Set.new(excludes)
    end

    def net_load
      production - consumption
    end

    def production
      CurveTools.add_curves(
        @order.participants.producers
          .reject { |part| @excludes.include?(part.key) }
          .map(&:load_curve)
      )
    end

    def consumption
      @order.demand_curve
    end
  end
end
