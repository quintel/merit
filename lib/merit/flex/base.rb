module Merit
  module Flex
    # Base class for all flexible producers which may store or use excess
    # energy from always-on producers.
    class Base < DispatchableProducer
      # Default attributes for all storage technologies. May be customised as
      # needed.
      DEFAULTS = { availability: 1.0, marginal_costs: :null }.freeze

      # Public: Returns the input capacity of each unit of this technology.
      #
      # Input capacity determines the maxiumum amount of energy which may be
      # consumed in each point. If no capacity is set, the output capacity is
      # used.
      #
      # Returns a float.
      attr_reader :input_capacity_per_unit

      # Public: Returns the share of excess which may be assigned.
      #
      # When a Flex producer belongs to a group of many other flex producers,
      # assigning a share will limit how much excess may be assigned, so as to
      # leave some for the other group members.
      #
      # Returns a float.
      attr_reader :excess_share

      # Public: The group of flexibles to which the participant optionally
      # belongs.
      #
      # Returns a Symbol.
      attr_reader :group

      def initialize(opts)
        super(DEFAULTS.merge(opts))

        @input_capacity_per_unit =
          opts[:input_capacity_per_unit] || opts[:output_capacity_per_unit]

        @output_capacity = available_output_capacity
        @input_capacity  = available_input_capacity

        raise(MissingGroup, opts[:key]) if opts[:excess_share] && !opts[:group]

        @excess_share = opts[:excess_share] || 1.0
        @group = opts[:group]
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
        input_cap = @input_capacity + @load_curve.get(point)

        amount = amount > input_cap ? input_cap : amount
        @load_curve.set(point, @load_curve.get(point) - amount)

        amount
      end

      # Public: Calculates the number of hours that the technology would run in if it were receiving
      # energy at its effective input capacity.
      def full_load_hours
        @full_load_hours ||
          if input_capacity_per_unit.zero? || number_of_units.zero?
            0.0
          else
            production / (input_capacity_per_unit * number_of_units * 3600)
          end
      end

      # Public: Describes how much energy is stored and may be emitted for
      # consumption in the chosen point.
      #
      # Returns a numeric.
      def max_load_at(_point)
        0.0
      end

      def available_at(point)
        max_load_at(point)
      end

      # Public: Assigns a load to this technology.
      #
      # Returns the load set.
      def set_load(point, value)
        @load_curve.set(point, value)
      end

      # Public: Determines the amount of energy the battery stored during the
      # Merit order calculation. It is assumed that the same amount of energy
      # will be emitted for use.
      #
      # Returns a float.
      def production(unit = :mj)
        mwh = @load_curve.select(&:negative?).sum(0.0).abs

        case unit
        when :mj  then mwh * 3600
        when :mwh then mwh
        else           raise "Unknown unit: #{ unit }"
        end
      end

      def flex?
        true
      end
    end # Base
  end # Flex
end
