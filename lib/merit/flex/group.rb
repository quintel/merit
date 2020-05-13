module Merit
  module Flex
    # Some Flexible participants may belong to a group, such that receive excess
    # energy at the same time. The group determines how this energy is shared
    # between its members.
    #
    # The default group behaves exactly like the normal calculation: energy is
    # given in order to each member. The order of members is determined by the
    # Sorting to which they belong.
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
      # collection - A Sorting instance, so the group know if and how to resort
      #              the members of the collection in each frame. May be empty.
      #
      # Returns a Group.
      def initialize(key, collection = Sorting::Fixed.new)
        @key = key
        @collection = collection
      end

      # Public: Adds a new participant to the group.
      #
      # Returns self.
      def insert(participant)
        @collection.insert(participant)
        self
      end

      # Public: Assigns energy to each member of the group in sorted order.
      #
      # Returns the total amount of energy taken by the participants.
      def assign_excess(point, amount)
        @collection.at_point(point).sum do |part|
          taken = part.assign_excess(point, amount)
          amount -= taken

          taken
        end
      end

      def to_a
        @collection.to_a
      end

      def inspect
        part_keys = @collection.at_point(0).map(&:key).join(', ')
        "#<#{self.class.name} #{@collection.class.name}(#{part_keys})>"
      end

      alias_method :to_s, :inspect
    end

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
