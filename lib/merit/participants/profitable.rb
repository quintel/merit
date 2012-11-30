# This (mixin) module includes every method for Producers with respect
# to finance, such as profit, revenue and cost.
module Merit::Profitable

  # Profitability
  def profitability
    if revenue > total_costs
      :profitable
    else
      if revenue > operating_costs
        :conditionally_profitable
      else
        :unprofitable
      end
    end
  end

  # Returns the absolute profit for the participant in EUR per MWh.
  def profit
    revenue - total_costs
  end

  # Returns the absolute amount of revenue in EUR.
  def revenue
    revenue_curve.reduce(:+)
  end

  # Returns a Curve with the revenue in EUR per point in time.
  def revenue_curve
    @revenue_curve ||= load_curve * order.price_curve
  end

  # Return the absolute total costs for the participant in EUR.
  def total_costs
    fixed_costs + variable_costs
  end

  # Returns the absolute fixed costs for the participant in EUR.
  def fixed_costs
    fixed_costs_per_unit * number_of_units
  end

  # Returns the costs that are dependent on the amount of production
  # in EUR per MWh.
  def variable_costs
    marginal_costs * production(:mwh)
  end

  # Returns the operating costs (OPEX) in EUR per MWh.
  def operating_costs
    fixed_om_costs + variable_costs
  end

  # Returns the fixed operating and maintenance costs in EUR per MWh.
  def fixed_om_costs
    fixed_om_costs_per_unit * number_of_units
  end

end
