module Merit
  # This (mixin) module includes every method for Producers with respect to
  # finance, such as profit, revenue and cost.
  module Profitable
    def profitability
      if revenue > total_costs
        :profitable
      elsif revenue > operating_costs
        :conditionally_profitable
      else
        :unprofitable
      end
    end

    # Returns the absolute profit for the participant in EUR per MWh.
    def profit
      revenue - total_costs
    end

    # Returns the absolute amount of revenue in EUR.
    def revenue
      if number_of_units.zero? || output_capacity_per_unit.zero?
        0.0
      else
        revenue_curve.reduce(:+)
      end
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
      @cost_strategy.variable_cost
    end

    # Returns the operating costs (OPEX) in EUR per MWh.
    def operating_costs
      fixed_om_costs + variable_costs
    end

    # Returns the fixed operating and maintenance costs in EUR per MWh.
    def fixed_om_costs
      fixed_om_costs_per_unit * number_of_units
    end

    # Returns the profits per MWh produced
    def profit_per_mwh_electricity
      production_mwh = production(:mwh)
      return nil if production_mwh.zero?
      profit / production_mwh
    end
  end
end
