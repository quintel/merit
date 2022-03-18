# frozen_string_literal: true

module Merit
  # A dispatchable producer whose availability may be specified with a curve rather than a numeric.
  #
  # For example:
  #
  #   curve = [1.0, 0.5] * (Merit::POINTS / 2)
  #   producer = Merit::VariableDispatchableProducer.new(..., availability: curve)
  #
  class VariableDispatchableProducer < DispatchableProducer
    def initialize(opts)
      raise MissingAttributeError.new(:availability, self.class) unless opts[:availability]

      if opts[:availability].is_a?(Numeric)
        raise(
          ArgumentError,
          'availability curve must be an array of values, use DispatchableProducer if you want ' \
          'to use a numeric availability'
        )
      end

      super(opts.merge(availability: CurveTools.availability_curve(opts[:availability])))
    end

    # Public: Determines what the max produced load is at a given point in time.
    #
    # Returns a numeric.
    def max_load_at(point)
      max_load_curve[point]
    end

    def available_output_capacity
      raise NotImplementedError, "available_output_capacity is not supported on #{self.class.name}"
    end

    # Public: Creates a curve describing the maximum supported load of the producer in each hour.
    #
    # Returns a Merit::Curve.
    def max_load_curve
      @max_load_curve ||= Curve.new(Array.new(Merit::POINTS) do |point|
        output_capacity_per_unit * availability[point] * number_of_units
      end.freeze).freeze
    end

    # Public: Calculates the maximum possible production of the producer, assuming it runs at full
    # capacity all year.
    #
    # Returns a Numeric.
    def max_production
      @max_production ||= max_load_curve.sum
    end
  end
end
