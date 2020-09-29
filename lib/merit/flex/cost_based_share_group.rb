# frozen_string_literal: true

require_relative 'group'

module Merit
  module Flex
    # A group which behaves like a hybrid of a Group and ShareGroup.
    #
    # For each hour in which excess is assigned to this group, it will assign fairly based on the
    # prices of the members. Members with lower prices wil receive energy first, while those which
    # have an equal price will have energy shared between them.
    #
    # This class makes heavy use of while loops and manual iteration. While we could create
    # subarrays (`array[start..end].each`) this allocates extra unwanted objects. Extracting the
    # while loops to a helper method which yields each participant would clean up the code and
    # reduce repitition, but takes nearly twice as long.
    class CostBasedShareGroup < Group
      # Public: Assigns energy to each member of the group in sorted order.
      #
      # Members with the same price will have the energy divided fairly between them based on their
      # remaining output capacity.
      #
      # Returns the total amount of energy taken by the participants.
      #
      # rubocop:disable Metrics/MethodLength
      def assign_excess(point, amount)
        initial_amount = amount
        recipients = @collection.at_point(point)
        index = 0

        while index < recipients.length && recipients[index]
          max_index = max_index_with_same_price(recipients, point, index)

          amount -=
            if index == max_index
              recipients[index].assign_excess(point, amount)
            else
              assign_excess_to_many(point, recipients, amount, index, max_index)
            end

          index = max_index + 1
        end

        initial_amount - amount
      end
      # rubocop:enable Metrics/MethodLength

      private

      # Internal: Given all the recipients sorted for the current point and an index of the
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

      # Internal: Assign an amount of excess energy fairly between all the participants between the
      # two indicies (end index INCLUSIVE).
      #
      # Energy will be assigned fairly between the participants based on their remaining capacity.
      #
      # point        - The current hour number.
      # recipients   - The array of all participants for the current hour (not just those to which
      #                load will be assigned).
      # amount       - The total amount of available excess energy.
      # start_index  - The index of the first participant to which load will be assigned.
      # finish_index - The index of the last participant to which load will be assigned.
      #
      # rubocop:disable Metrics/MethodLength
      def assign_excess_to_many(point, recipients, amount, start_index, finish_index)
        total_capacity = 0.0
        assigned = 0.0

        index = start_index
        while index <= finish_index
          total_capacity += recipients[index].unused_input_capacity_at(point)
          index += 1
        end

        index = start_index
        while index <= finish_index
          recipient = recipients[index]
          share = recipient.unused_input_capacity_at(point) / total_capacity
          assigned += recipient.assign_excess(point, amount * share)
          index += 1
        end

        assigned
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
