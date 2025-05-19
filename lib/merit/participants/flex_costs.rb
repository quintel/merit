# frozen_string_literal: true

module Merit
  # This (mixin) module includes base methods for Flex participants with respect to
  # fuel costs and revenue. To be injected into the graph after calculation.
  module FlexCosts
    include Profitable

    # TODO: CHeck COSTS comment on everybody here and double check adapters in the engine

    # Public: Returns the absolute amount of fuel costs of electricity in EUR.
    #
    # For Users, this represents fuel costs
    def fuel_costs
      @fuel_costs ||=
        if number_of_units.zero? || input_capacity_per_unit.zero?
          0.0
        else
          # TODO: no need for abs when fuel costs curve becomes positive
          fuel_costs_curve.sum.abs
        end
    end

    # It's negativeeeee :(
    def fuel_costs_curve
      @fuel_costs_curve ||= load_price_curve.clip_negative
    end

    def revenue_curve
      # WATCH OUT! for production_mwh we take the negative values?! But that is charging..
      # Positive should be what it is emitting - but what if battery does not discharge fully at the end of the year?
      @revenue_curve ||= load_price_curve.clip_positive
    end

    def load_price_curve
      @load_price_curve ||= load_curve * order.price_curve
    end



    # Is production same as emitted same as stored? Always? What about decay?
    # And is it the same as consumption? What if the battery is left with stored energy inside?


    def fuel_costs_per_mwh
      # TODO: double check here -> consumption is not neccessarily the same for all participants??
      # Is consumption not negative??
      consumpition_mwh = load_curve.select(&:positive?).sum(0.0).abs
      return if consumpition_mwh.zero?

      fuel_costs / consumpition_mwh
    end
  end
end
