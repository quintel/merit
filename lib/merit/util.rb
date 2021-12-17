# frozen_string_literal: true

module Merit
  # Helpful methods.
  module Util
    module_function

    # Public: Given an array, and start and finish indexes, iterates through the slice yielding
    # each element. The yielded elements are inclusive of the `start` and `finish` indices.
    #
    # For example:
    #
    #   Util.slice_each([1, 2, 3, 4, 5], 1, 3) { |v| ... }
    #   #                  ^  ^  ^
    #   #              Yielded values
    #
    # Returns the elements.
    def slice_each(elements, start, finish = nil)
      finish ||= elements.length - 1

      while start <= finish
        yield elements[start]
        start += 1
      end

      elements
    end
  end
end
