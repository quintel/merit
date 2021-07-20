# frozen_string_literal: true

module Merit
  module Flex
    # A consumer which will take as much excess energy as its capacity allows. No energy is ever
    # returned to the merit order in subsequent points.
    #
    # Such producers are always a consumer of last resort and will never take energy from
    # dispatchables.
    class BlackHole < Base
      # Ensures BlackHoles are always used last.
      class CostStrategy < ::Merit::CostStrategy::Null
        def sortable_cost(*)
          -Float::INFINITY
        end
      end

      def initialize(opts)
        @cost_strategy = CostStrategy.new(self)
        super(opts.merge(output_capacity_per_unit: 0.0))
      end

      def max_load_at(_point)
        0.0
      end

      def consume_from_dispatchables?
        false
      end
    end
  end
end
