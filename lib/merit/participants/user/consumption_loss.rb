# frozen_string_literal: true

module Merit
  class User
    # A user which receives the total demand of all other consumers and creates
    # a demand which is an additional percentage of that demand.
    #
    # For example, if demand in frame 0 is 50, and a ConsumptionLoss consumer
    # has a `share` of 0.2, its demand will be 10, resulting in a total demand
    # for frame 0 of 60.
    class ConsumptionLoss < User
      def initialize(options)
        super

        require_attributes :consumption_share

        @load_curve = Curve.new
        @consumption_share = options[:consumption_share]
      end

      def dependent?
        true
      end

      def load_at(point, other_demands)
        return @load_curve[point] if other_demands.nil?

        @load_curve[point] = other_demands * @consumption_share
      end
    end
  end
end
