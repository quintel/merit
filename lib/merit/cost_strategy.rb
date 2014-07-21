module Merit
  # Contains classes which know how to calculate the cost of a producer. Each
  # strategy should implement at least one method: "marginal_cost". This accetps
  # an optional "point" argument telling it for which hour in the year we want
  # to calculate the cost.
  #
  # An optional "sortable_cost" method, with the same signature, is used to sort
  # producers prior to calculating points in the merit order.
  module CostStrategy
    # Public: Given a producer, returns a cost strategy suitable to perform the
    # calculation.
    def self.create(producer, options)
      if options[:cost_curve]
        FromCurve.new(producer, options[:cost_curve])
      elsif options[:cost_spread]
        args = options.values_at(:marginal_costs, :cost_spread)
        LinearCostFunction.new(producer, *args)
      elsif options[:marginal_costs]
        Constant.new(producer, options[:marginal_costs])
      else
        fail(NoCostData.new(producer))
      end
    end

    # An abstract cost calculator from which real cost calculators should
    # inherit.
    class Base
      attr_reader :producer

      # Public: Creates a new CostStrategy which knows how to determine the cost
      # (or, sometimes, price) of a producer in a particular hour of the year.
      #
      # producer - The producer whose cost will be calculated.
      #
      # Returns a cost strategy.
      def initialize(producer)
        @producer = producer
      end

      # Public: Determines the final marginal cost of the producer. Accepts and
      # discards any arguments given; subclasses may instead take a single
      # "point" argument to tell it which hour is being calculated.
      #
      # This method should be called only after the merit order has been
      # calculated as subclasses may rely on data from the calculation. Prior to
      # then, use "sortable_cost" instead.
      #
      # Returns a Numeric.
      def marginal_cost
        fail NotImplementedError
      end

      # Public: Determines the marginal cost of the producer. In some cases,
      # this will differ from "marginal_cost" if the final marginal cost depends
      # on data from the merit order calculation.
      #
      # Returns a Numeric.
      def sortable_cost(*args)
        marginal_cost(*args)
      end

      # Public: The variable cost of a producer is the marginal cost multiplied
      # by the production.
      #
      # Returns a Numeric.
      def variable_cost
        marginal_cost * @producer.production(:mwh)
      end

      # Public: Tells us if the price changes depending on the point in the year
      # being calculated. If the merit order has one or more producers with a
      # cost which varies by hour, the producer list has to be resorted prior to
      # every point calculation.
      #
      # Returns true or false.
      def variable?
        false
      end
    end # Base

    # A cost strategy which simply reads a "marginal_costs" attribute from the
    # producer. The cost is constant, and does not changed depending on the hour
    # being calculated.
    #
    # Create your producer providing a "marginal_costs" attribute:
    #
    #   Producer.new(marginal_costs: 30.5, ...)
    #
    class Constant < Base
      def initialize(producer, cost)
        super(producer)
        @cost = cost
      end

      def marginal_cost
        @cost
      end
    end # Constant

    # Calculates the marginal cost of the producer by reading the value from a
    # curve. The cost may change depending on the hour.
    #
    # Create your producer like so:
    #
    #   Producer.new(cost_curve: Curve.new(...), ...)
    #
    class FromCurve < Base
      def initialize(producer, curve)
        super(producer)
        @curve = curve
      end

      def sortable_cost(point)
        @curve.get(point)
      end

      def marginal_cost
        variable_cost / @producer.production(:mwh)
      end

      def variable_cost
        (@producer.load_curve * @curve).reduce(:+)
      end

      def variable?
        true
      end
    end # FromCurve

    # Calculates the marginal cost of a producer using a linear step function,
    # slightly increasing costs with demand.
    #
    # Create your producer like so:
    #
    #   Producer.new(cost_function: { mean: 100.0, spread: 0.02 }, ...)
    #
    # See https://github.com/quintel/merit/issues/109
    class LinearCostFunction < Base
      def initialize(producer, mean, spread)
        super(producer)

        @mean   = mean
        @spread = spread
      end

      def marginal_cost
        linear_cost_function(@producer.production(:mwh) / Merit::POINTS)
      end

      def sortable_cost(*)
        @mean
      end

      #######
      private
      #######

      # Internal: Calculates the cost of the producer according to a linear step
      # function, whereby the cost increases slightly as capacity increases.
      # Each "step" in the function corresponds with an increase in the number
      # of units required to satisfy demand.
      #
      # See https://github.com/quintel/merit/issues/109
      #
      # Returns a Numeric.
      def linear_cost_function(capacity)
        typical = @producer.output_capacity_per_unit
        avail   = @producer.available_output_capacity

        y_min = @mean * (1 - @spread / 2)
        y_max = @mean * (1 + @spread / 2)

        delta = y_max - y_min

        y_min + (capacity / typical).floor *
          delta / (avail / typical)
      end
    end # LinearCostFunction
  end # CostStrategy
end # Merit
