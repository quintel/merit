# frozen_string_literal: true

module Merit
  module Flex
    # Some Flexible participants may belong to a group, such that receive excess energy at the same
    # time. The group determines how this energy is shared between its members.
    #
    # The default group behaves exactly like the normal calculation: energy is given in order to
    # each member. The order of members is determined by the Sorting to which they belong.
    #
    # For example:
    #
    #   # A group where the order of members is constant.
    #   Merit::Flex::Group.new(Merit::Sorting::Fixed.new)
    #
    #   # A group where the order of members is recomputed in each point
    #   # according to its sortable cost.
    #   sorting = Merit::Sorting::Variable do |participant, point|
    #     participant.cost_strategy.sortable_cost(point)
    #   end
    #
    #   Merit::Flex::Group.new(sorting)
    class Group < Base
      attr_reader :key

      # Public: Creates a new group.
      #
      # key        - Unique key to identify this group in the merit order.
      # collection - An optional Sorting instance containing members of the group. If none is
      #              provided, the group will be unsorted. If a Sorting::Fixed is provided, it will
      #              be swapped out for a Sorting::Variable if any variably-priced members are
      #              added.
      #
      # Returns a Group.
      def initialize(key, collection = Sorting::Unsorted.new)
        @key = key
        @collection = collection
      end

      # Public: Adds a new participant to the group.
      #
      # Returns self.
      def insert(participant)
        @collection = @collection.to_variable if must_become_variable?(participant)

        @collection.insert(participant)
        self
      end

      # Public: Assigns energy to each member of the group in sorted order.
      #
      # Returns the total amount of energy taken by the participants.
      def assign_excess(point, amount)
        @collection.at_point(point).reduce(0.0) do |memo, part|
          break memo unless amount.positive?

          taken = part.assign_excess(point, amount)
          amount -= taken

          memo + taken
        end
      end

      # Public: Reduces the group to the simplest possible participant.
      #
      # A group with only one member has no special assignment or sorting behavior, and can
      # therefore be replaced by the member.
      #
      # Returns a Group or Participant.
      def simplify
        @collection.length == 1 ? @collection.first : self
      end

      def to_a
        @collection.to_a
      end

      def inspect
        part_keys = @collection.at_point(0).map(&:key).join(', ')
        "#<#{self.class.name} #{@collection.class.name}(#{part_keys})>"
      end

      alias_method :to_s, :inspect

      def cost_strategy
        @cost_strategy ||= CostStrategy.create(self, marginal_costs: sortable_cost)
      end

      def consume_from_dispatchables?
        @collection.all? { |flex| flex.consume_from_dispatchables? }
      end

      private

      def sortable_cost
        if @collection.empty?
          :null
        else
          @collection.sum { |el| el.cost_strategy.sortable_cost } / @collection.length
        end
      end

      def must_become_variable?(participant)
        return false if @collection.is_a?(Sorting::Variable)
        return false unless @collection.sortable?
        return false unless participant.cost_strategy.variable?

        true
      end
    end
  end
end
