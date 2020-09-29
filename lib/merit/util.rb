# frozen_string_literal: true

module Merit
  # Helpful methods.
  module Util
    module_function

    # Internal: Given participants already sorted by cost for the current point, and an index of the
    # "current" participant, returns the index of the last participant whose price is the same as
    # that of the current.
    #
    # For example, if we have recipients with costs [1, 2, 2, 2, 3] and the current index is 1
    # (the second participant), the maximum index with the same price is 3 (the fourth item).
    #
    # Returns an integer.
    def max_index_with_same_price(recipients, point, index)
      max_index = index
      cost = recipients[index].cost_strategy.sortable_cost(point)

      while recipients[max_index + 1] &&
          recipients[max_index + 1].cost_strategy.sortable_cost(point) == cost
        max_index += 1
      end

      max_index
    end

    # Public: Given an array, and start and finish indexes, iterates through the slice yielding each
    # element. This provides an alternative to Enumerable#sum which doesn't require allocating the
    # array sub-slice first (`arr[1..3].sum`).
    #
    # Both indicies are INCLUSIVE.
    #
    # For example:
    #
    #   Util.sum_slice([1, 2, 3, 4, 5], 1, 3) { |v| v } # => 9
    #   #                  ^  ^  ^
    #   #              Yielded values
    #
    # Returns the sum of the values returned to block.
    def sum_slice(elements, start, finish)
      memo = 0.0

      while start <= finish
        memo += yield(elements[start])
        start += 1
      end

      memo
    end
  end
end
