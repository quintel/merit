module Merit
  module Flex
    # Some flexible participants may belong to a group. These participants need
    # to be assigned excess energy fairly based on their "excess_share", but are
    # still treated as individuals for dispatchable purposes.
    class Group < Base
      attr_reader :key

      def initialize(component)
        @components = [component]
        @key = component.group
      end

      # Public: Adds a new component to the group.
      #
      # Returns self.
      def insert(component)
        @components.push(component)
        self
      end

      # Public: Assigns excess energy to each member of the group, fairly and in
      # accordance with their "excess_share".
      #
      # Returns the total amount of energy assigned; may be less than was given.
      def assign_excess(point, amount)
        @components.reduce(0) do |sum, comp|
          sum + comp.assign_excess(point, amount * comp.excess_share)
        end
      end
    end
  end
end
