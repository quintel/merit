# frozen_string_literal: true

require 'forwardable'

module Merit
  module Flex
    # Wraps all the flexible technologies in a merit order.
    #
    # This groups technologies by their price (using Group). When the flex technologies all have
    # fixed pricing, this allows us to create these groups once, rather than having to recreate them
    # in every point of the calculation
    class Collection
      extend Forwardable
      include Enumerable

      def_delegator :@collection, :each

      def initialize(sortable)
        @collection = sortable

        # When all items in the collection have fixed pricing, we can use the same groups rather
        # than having than having to rebuild the groups for every point in the calculation.
        @sorted = Group.from_collection(sortable) unless sortable.is_a?(Sorting::Variable)
      end

      def at_point(point)
        @sorted || Group.from_collection(@collection, point)
      end
    end
  end
end
