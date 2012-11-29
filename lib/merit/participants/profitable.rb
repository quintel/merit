# This (mixin) module includes every method for Producers with respect
# to finance, such as profit, revenue and cost.
module Merit::Profitable

  # Returns the costs that are dependent on the amount of production
  # in EUR per MWh.
  def variable_costs
    marginal_costs * production(:mwh)
  end

  # Returns the absolute amount of revenue in EUR.
  def revenue
    revenue_curve.reduce(:+)
  end

  # Returns a Curve with the revenue in EUR per point in time.
  def revenue_curve
    load_curve * order.price_curve
  end

end
