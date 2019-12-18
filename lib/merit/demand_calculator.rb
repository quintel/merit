# frozen_string_literal: true

module Merit
  # Calculates the demand of an Order in each point. DemandCalculator assumes
  # that all demands are independent, and do not change depending on other
  # sources of demand.
  class DemandCalculator
    # Public: Creates a calculator suitable for the users in the order.
    #
    # Returns a DemandCalculator when no users are dependent on others; returns
    # a Dependent otherwise.
    def self.create(users)
      users.any?(&:dependent?) ? Dependent.new(users) : new(users)
    end

    def initialize(users)
      @users = users
    end

    def demand_at(point)
      @users.sum { |user| user.load_at(point) }
    end

    # Calculates demand of a merit order when the order has one or demands which
    # depend on the total demand of other users.
    class Dependent < self
      def initialize(users)
        super
        @dependent, static = users.partition(&:dependent?)

        @flex = users.select { |user| user.is_a?(Flex::Base) }
        @static = static - @flex
      end

      def demand_at(point)
        # Energy which will definitely be consumed in this hour.
        instantaneous = @static.sum { |user| user.load_at(point) }

        # Energy which will be produced in this hour, including that which may
        # not be consumed immediately.
        total = instantaneous + @flex.sum { |user| user.load_at(point) }

        @dependent.each do |user|
          amount = user.load_at(point, instantaneous)

          instantaneous += amount
          total += amount
        end

        total
      end
    end
  end
end
