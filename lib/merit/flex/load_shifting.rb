# frozen_string_literal: true

module Merit
  module Flex
    # Load shifting acts like reverse storage: it outputs energy now, like a dispatchable, and
    # stores a "deficit" which it must satisfy later.
    #
    # The amount of demand which may be shifted in each hour is constrained by a "limiting curve".
    #
    # It is assumed that energy passes through a LoadShifting participant without any conversions
    # or losses taking place.
    #
    # LoadShifting will emit energy when its price is lower than that of the electricity market,
    # and will receive energy only to replace what was output in earlier hours. Implemented as a
    # flex technology, LoadShifting may have a marginal_cost which governs the price paid for
    # energy output, and a consumption_price for the energy consumed.
    #
    # As load shifting must be neutral throughout the year, it is modelled with two related
    # participants both of which must be added to the Merit order participants:
    #
    #   * Flexible: The flexible part acts as a flexible participant, emitting energy and internally
    #     storing a deficit which it will try to reclaim through consumption later in the year.
    #   * Inflexible: When a shifted load cannot be shifted any further (due to time limits, or
    #     nearing the end of the year), the Inflexible component ensures that the load is placed on
    #     the network, regardless of the energy price. The Flexible participant is notified of this
    #     load and its deficit reduced accordingly.
    module LoadShifting
      # Public: Given options for a LoadShifting participant, contains an array containing the
      # flexible and inflexible participants needed to model load shifting.
      #
      # The flexible part should be considered the public interface for load shifting, with the
      # inflexible part used to ensure that load shifting is energy neutral throughout the year.
      def self.build(opts)
        flexible = Flexible.new(opts)
        inflexible = Inflexible.new(key: :"#{flexible.key}_inflexible", flexible: flexible)

        [flexible, inflexible]
      end

      # Flexible is the main participant for load shifting. It emits energy and later tries to
      # reclaim it from producers.
      class Flexible < Merit::Flex::Base
        attr_reader :deficit

        def initialize(opts)
          super

          @limiting_curve = opts.fetch(:limiting_curve)
          @deficit_capacity = [opts[:deficit_capacity] || Float::INFINITY, 0].max
          @deficit = 0.0
        end

        # Energy output
        # -------------

        # Public: Returns how much energy can be produced by the participant at this point in
        # time. This amount is limited by the demand of downstream participants (the limiting curve)
        # and the capacity of the participant itself.
        #
        # Returns a numeric.
        def available_at(point)
          current = load_at(point)

          # Can't output if the participant already has input.
          return 0.0 if current.negative? || mandatory_input_at(point).positive?

          headroom = [@output_capacity, @limiting_curve[point]].min
          available = [headroom - current, 0.0].max

          [@deficit_capacity - @deficit, available].min
        end

        alias_method :max_load_at, :available_at

        # Public: Sets an amount of energy to be produced by the participant at this point in time.
        #
        # This method does not check that the amount is lower or equal to the limiting curve or the
        # participant capacity. You should limit the amount by `available_at` first.
        #
        # point  - The hour number.
        # amount - The amount of energy.
        #
        # Returns the amount.
        def set_load(point, amount)
          prev = load_at(point)

          super

          @deficit += amount - prev

          amount
        end

        # Energy input
        # ------------

        # Public: Assigns energy to be consumed by the participant.
        #
        # The amount consumed will be limited by the capacity of the participant, and by the deficit
        # currently stored.
        #
        # point  - The hour number.
        # amount - The amount of energy.
        #
        # Returns the actual amount of energy consumed. May be lower than the given amount.
        def assign_excess(point, amount)
          current = load_at(point)

          # Can't accept input if the participant has already output.
          return 0.0 if current.positive?

          # current may be negative; some energy has already been input in this hour.
          amount = [amount, @input_capacity + current, @deficit].min

          load_curve[point] -= amount

          @deficit -= amount
          amount
        end

        # Public: Returns how much energy the load shifting participant requires be placed on the
        # energy network in the given hour.
        #
        # Loads by the Flexible participant are optional, and only placed on the electricity network
        # when the price constraints are satisified. However, loads sometimes must be placed
        # regardless of the constraints. In those hours, the load is considered "mandatory" and will
        # be placed by an Inflexible companion participant.
        #
        # Returns a numeric.
        def mandatory_input_at(point)
          remaining_points = Merit::POINTS - point - 1

          return @deficit if remaining_points.zero?

          future_available = @input_capacity * remaining_points
          [@deficit - future_available, 0.0].max
        end
      end

      # Inflexible is used to ensure load shifting is energy neutral throughout the year.
      class Inflexible < Merit::User
        public_class_method :new

        def initialize(opts)
          super

          # The inflexible participant is publically considered as having no load. If the curve is
          # ever queried (for example, to calculate net load) it can be ignored with the Flexible
          # participant containing the load for both parts.
          @load_curve = Merit::Curve.new

          @flexible = opts.fetch(:flexible)
          @last_load = 0.0
          @last_point = -1

          # Used to track if something called load_at for an earlier point than has been calculated
          @rewound = false
        end

        def load_at(point)
          @rewound = true if point < @last_point

          return 0.0 if @rewound
          return @last_load if point == @last_point

          @last_load = @flexible.mandatory_input_at(point)
          @last_point = point

          return @last_load if @last_load.zero?

          @flexible.assign_excess(point, @last_load)
        end
      end
    end
  end
end
