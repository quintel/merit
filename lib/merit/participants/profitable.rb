# frozen_string_literal: true

module Merit
  # This (mixin) module includes every method for Producers with respect to finance, such as profit,
  # revenue and cost.
  module Profitable
    include Finance

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
      @revenue ||=
        if number_of_units.zero? || output_capacity_per_unit.zero?
          0.0
        else
          revenue_curve.sum
        end
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

    # Returns the operating costs per MWh produced
    def operating_costs_per_mwh
      production_mwh = production(:mwh)
      return nil if production_mwh.zero?

      operating_costs / production_mwh
    end

    # Returns the profits per MWh produced
    def profit_per_mwh_electricity
      production_mwh = production(:mwh)
      return nil if production_mwh.zero?

      profit / production_mwh
    end

    # Returns the revenue per MWh produced.
    def revenue_per_mwh
      production_mwh = production(:mwh)
      return nil if production_mwh.zero?

      revenue / production_mwh
    end
  end
end
