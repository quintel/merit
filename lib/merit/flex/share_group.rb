# frozen_string_literal: true

require_relative 'group'

module Merit
  module Flex
    # Some flexible participants may belong to a group. These participants need
    # to be assigned excess energy fairly based on their "excess_share", but are
    # still treated as individuals for dispatchable purposes.
    class ShareGroup < Group
      # Public: Assigns excess energy to each member of the group, fairly and in
      # accordance with their "excess_share".
      #
      # Returns the total amount of energy assigned; may be less than was given.
      def assign_excess(point, amount)
        @collection.at_point(point).sum do |part|
          part.assign_excess(point, amount * part.excess_share)
        end
      end
    end
  end
end
