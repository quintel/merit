module Merit
  # Represents a source of energy from outside the region. Unlike Producers, an
  # interconnect has a marginal price which varies over time.
  #
  # Do not give SupplyInterconnect a ":marginal_cost" value, but instead provide
  # the price in a Curve, where each value in the curve represents the marginal
  # cost for that hour. For example:
  #
  #   prices = Curve([1.0, 2.0, 1.2, 2.2, ...])
  #   conn   = SupplyInterconnect.new(cost_curve: prices, ...)
  #
  # Any ":number_of_units" value will be ignored; we always assume a value of 1.
  class SupplyInterconnect < DispatchableProducer
    # Public: Creates a supply interconnect.
    def initialize(options)
      super(options.merge(number_of_units: 1))
    end
  end # SupplyInterconnect
end # Merit
