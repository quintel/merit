# frozen_string_literal: true

module Merit
  # Helpful methods.
  module Util
    module_function

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
