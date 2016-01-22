module Merit
  module Flex
    class Base < DispatchableProducer
      # Default attributes for all storage technologies. May be customised as
      # needed.
      DEFAULTS = { availability: 1.0 }.freeze

      def initialize(opts)
        super(DEFAULTS.merge(opts).merge(marginal_costs: 0.0))
        @capacity = available_output_capacity
      end

      # Public: Stores a given amount of energy in the technology. Not all given
      # to the technology is guaranteed to be stored.
      #
      # Returns the amount of energy which was accepted by the storage device.
      def assign_excess(point, amount)
        amount = amount > @capacity ? @capacity : amount
        load_curve.set(point, load_curve.get(point) - amount)

        amount
      end

      # Public: Describes how much energy is stored and may be emitted for
      # consumption in the chosen point.
      #
      # Returns a numeric.
      def max_load_at(point)
        0.0
      end

      # Public: Assigns a load to this technology.
      #
      # Returns the load set.
      def set_load(point, value)
        load_curve.set(point, value) unless value.zero?
      end
    end # Base
  end # Flex
end
