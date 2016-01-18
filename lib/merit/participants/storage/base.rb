module Merit
  module Storage
    class Base < DispatchableProducer
      attr_reader :reserve

      def initialize(opts)
        super(opts.merge(marginal_costs: 0.0, availability: 1.0))

        @capacity          = available_output_capacity
        @input_efficiency  = opts[:input_efficiency]  || 0.85
        @output_efficiency = opts[:output_efficiency] || 0.89

        @reserve = Reserve.new(
          opts.fetch(:volume_per_unit) * opts.fetch(:number_of_units)
        )
      end

      # Public: Stores a given amount of energy in the technology. Not all given
      # to the technology is guaranteed to be stored.
      #
      # Returns the amount of energy which was accepted by the storage device.
      def store(point, amount)
        amount = (amount > @capacity ? @capacity : amount) * @input_efficiency
        stored = @reserve.add(point, amount) / @input_efficiency

        load_curve.set(point, stored.zero? ? 0.0 : -stored)

        stored
      end

      # Public: Describes how much energy is stored and may be emitted for
      # consumption in the chosen point.
      #
      # Returns a numeric.
      def available_at(point)
        in_reserve = @reserve.at(point) * @output_efficiency
        in_reserve > @capacity ? @capacity : in_reserve
      end

      alias_method :max_load_at, :available_at

      # Public: Assigns a load to this storage technology. Subtracts the energy
      # from the reserve.
      #
      # Returns nothing.
      def set_load(point, value)
        @reserve.take(point, value / @output_efficiency)
        load_curve.set(point, value)
      end
    end # Base
  end # Storage
end
