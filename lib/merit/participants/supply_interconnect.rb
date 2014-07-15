module Merit
  # Represents a source of energy from outside the region. Unlike Producers, an
  # interconnect has a marginal price which varies over time.
  #
  # Do not give SupplyInterconnect a ":marginal_cost" value, but instead provide
  # the price in a Curve, where each value in the curve represents the marginal
  # cost for that hour. For example:
  #
  #   prices = Curve([1.0, 2.0, 1.2, 2.2, ...])
  #   conn   = SupplyInterconnect.new(price_curve: prices, ...)
  #
  # Any ":number_of_units" value will be ignored; we always assume a value of 1.
  class SupplyInterconnect < DispatchableProducer
    # Public: Creates a supply interconnect.
    def initialize(options)
      super(options.merge(number_of_units: 1))

      @price_curve = options[:price_curve] ||
        fail(MissingPriceCurve.new(options[:key]))
    end

    # Public: Returns the marginal cost of the producer -- the cost which will
    # be incurred by increasing the number of units by 1.
    #
    # Interconnector pricing is determined with a curve, therefore there is no
    # single marginal cost we can return.
    #
    # Raises a VariableMarginalCost error.
    def marginal_costs(*)
      fail VariableMarginalCost.new(self)
    end

    # Public: Returns the marginal cost of the producer. SupplyInterconnect
    # costs vary over time according to a curve, therefore we cannot return a
    # single marginal cost value.
    def variable_costs
      (@price_curve * @load_curve).reduce(:+)
    end

    # Public: Returns the marginal cost of the interconnect in the given point.
    def marginal_cost_at(point)
      @price_curve.get(point)
    end
  end # SupplyInterconnect
end # Merit
