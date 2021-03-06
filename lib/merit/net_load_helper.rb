module Merit
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
          .reject(&method(:excluded_from_participating))
          .map(&:load_curve)
      )
    end

    def excluded_from_participating(producer)
      @excludes.include?(producer.key)
    end

    def consumption
      @order.demand_curve
    end
  end
end
