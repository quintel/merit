# frozen_string_literal: true

module Merit
  # This (mixin) module includes base methods for Participants with respect to
  # basic finance, such as revenue/fuel cost.
  module Finance
    # Returns the absolute amount of revenue in EUR.
    #
    # For Users, this represents fuel costs
    def revenue
      @revenue ||= revenue_curve.sum
    end

    # Returns a Curve with the revenue in EUR per point in time.
    def revenue_curve
      @revenue_curve ||= load_curve * order.price_curve
    end
  end
end
