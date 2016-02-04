module Merit
  module Flex
    class Base < DispatchableProducer
      # Default attributes for all storage technologies. May be customised as
      # needed.
      DEFAULTS = { availability: 1.0 }.freeze

      # Public: Returns the input capacity of each unit of this technology.
      #
      # Input capacity determines the maxiumum amount of energy which may be
      # consumed in each point. If no capacity is set, the output capacity is
      # used.
      #
      # Returns a float.
      attr_reader :input_capacity_per_unit

      def initialize(opts)
        super(DEFAULTS.merge(opts).merge(marginal_costs: :null))

        @input_capacity_per_unit =
          opts[:input_capacity_per_unit] || opts[:output_capacity_per_unit]

        @output_capacity = available_output_capacity
        @input_capacity  = available_input_capacity
      end

      # Public: The total input capacity of all units of this technology.
      #
      # Returns a float.
      def available_input_capacity
        @available_input_capacity ||=
          input_capacity_per_unit * availability * number_of_units
      end

      # Public: Stores a given amount of energy in the technology. Not all given
      # to the technology is guaranteed to be stored.
      #
      # Returns the amount of energy which was accepted by the storage device.
      def assign_excess(point, amount)
        input_cap = @input_capacity + load_curve.get(point)

        amount = amount > input_cap ? input_cap : amount
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

      # Public: Determines the amount of energy the battery stored during the
      # Merit order calculation. It is assumed that the same amount of energy
      # will be emitted for use.
      #
      # Returns a float.
      def production(unit = :mj)
        mwh = (load_curve.select { |v| v < 0 }.reduce(:+) || 0.0).abs

        case unit
          when :mj  then mwh * 3600
          when :mwh then mwh
          else           fail "Unknown unit: #{unit}"
        end
      end
    end # Base
  end # Flex
end
