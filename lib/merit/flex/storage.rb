module Merit
  module Flex
    class Storage < Base
      attr_reader :reserve

      # Public: Creates a new Storage participant which may retain excess energy
      # produced by always-on producers so that it may be used later.
      def initialize(opts)
        super

        @input_efficiency  = opts[:input_efficiency]  || 1.0
        @output_efficiency = opts[:output_efficiency] || 1.0

        decay = if opts[:decay]
          units = number_of_units
          ->(point, amount) { opts[:decay].call(point, amount) * units }
        end

        @reserve = Reserve.new(
          opts.fetch(:volume_per_unit) * number_of_units * availability, &decay
        )
      end

      def assign_excess(point, amount)
        input_cap = @input_capacity + load_curve.get(point)

        amount  = amount > input_cap ? input_cap : amount
        amount *= @input_efficiency

        stored  = @reserve.add(point, amount) / @input_efficiency

        load_curve.set(point, load_curve.get(point) - stored)

        stored
      end

      def max_load_at(point)
        in_reserve = @reserve.at(point) * @output_efficiency
        in_reserve > @output_capacity ? @output_capacity : in_reserve
      end

      # Public: Assigns the load to the storage technology and retains the
      # energy in the reserve for future use.
      #
      # Returns the load.
      def set_load(point, amount)
        super

        unless amount.zero?
          @reserve.take(point, amount / @output_efficiency)
        end

        amount
      end
    end # Storage
  end # Flex
end
