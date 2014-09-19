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
      elsif options[:marginal_costs] == :null
        Null.new(producer)
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

      # Public: Returns the price of the producer. This is subtly different from
      # the cost in that the price is used to determine the price of an entire
      # region in a particular hour. Only one producer is price-setting.
      #
      # Returns a Numeric.
      def price_at(point, allow_loaded = false)
        assert_price_setting!(point, allow_loaded)
        marginal_cost
      end

      # Public: Returns the cost of the producer at a given point in time.
      #
      # Returns a numeric.
      def cost_at(point)
        marginal_cost
      end

      # Public: Determines the marginal cost of the producer. In some cases,
      # this will differ from "marginal_cost" if the final marginal cost depends
      # on data from the merit order calculation.
      #
      # Returns a Numeric.
      def sortable_cost(*args)
        marginal_cost
      end

      # Public: The variable cost of a producer is the marginal cost multiplied
      # by the production.
      #
      # Returns a Numeric.
      def variable_cost
        marginal_cost * @producer.production(:mwh)
      end

      # Public: Returns if the producer may be used to set the price of the
      # region for a given point. Note that this does not mean that this IS the
      # price-setting producer; merely that it is valid to be used in such a
      # way.
      def price_setting?(point)
        @producer.provides_price? || @producer.load_curve.get(point).zero?
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

      #######
      private
      #######

      def assert_price_setting!(point, allow_loaded)
        unless allow_loaded || price_setting?(point)
          fail InsufficentCapacityForPrice.new(@producer, point)
        end
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

    # A cost strategy which has no cost and whose producer will never be
    # price-setting. For example, storage.
    class Null < Constant
      def initialize(producer)
        super(producer, 0.0)
      end

      def price_setting?(*)
        false
      end
    end # Null

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

      def price_at(point, allow_loaded = false)
        assert_price_setting!(point, allow_loaded)
        sortable_cost(point)
      end

      def cost_at(point)
        sortable_cost(point)
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
        cost_at_load(@producer.production(:mwh) / Merit::POINTS)
      end

      def cost_at(point)
        cost_at_load(@producer.load_curve.get(point))
      end

      def price_at(point, allow_loaded = false)
        if @producer.provides_price?
          cost_at_load(@producer.load_curve.get(point))
        else
          assert_price_setting!(point, allow_loaded)

          cost_at_load(
            @producer.output_capacity_per_unit +
            @producer.load_curve.get(point)
          )
        end
      end

      def price_setting?(point)
        return true if super

        pricing_load =
          @producer.output_capacity_per_unit +
          @producer.load_curve.get(point)

        pricing_load <= @producer.available_output_capacity
      end

      def sortable_cost(*)
        @mean
      end

      # Internal: Calculates the cost of the producer according to a linear step
      # function, whereby the cost increases slightly as capacity increases.
      # Each "step" in the function corresponds with an increase in the number
      # of units required to satisfy demand.
      #
      # See https://github.com/quintel/merit/issues/109
      #
      # Returns a Numeric.
      def cost_at_load(capacity)
        typical = @producer.output_capacity_per_unit
        avail   = @producer.available_output_capacity

        return Float::INFINITY if avail.zero?

        y_min = @mean * (1 - @spread / 2)
        y_max = @mean * (1 + @spread / 2)

        delta = y_max - y_min

        y_min + (capacity / typical).floor *
          delta / (avail / typical)
      end
    end # LinearCostFunction
  end # CostStrategy
end # Merit
