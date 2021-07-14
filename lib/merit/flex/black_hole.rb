# frozen_string_literal: true

module Merit
  module Flex
    # A consumer which will take as much excess energy as its capacity allows. No energy is ever
    # returned to the merit order in subsequent points.
    class BlackHole < Base
      def initialize(opts)
        super(opts.merge(volume_per_unit: Float::INFINITY))
      end

      def max_load_at(_point)
        0.0
      end
    end
  end
end
