module Merit
  # Loss of Load Expectation
  #
  # This helper module is used to calculate the expectation that demand for
  # electricity will exceed available supply.
  class LOLE
    # Public: Creates a new LOLE calculator.
    def initialize(order)
      @order = order
    end

    # Public: Given a +demand+ placed on the graph, and a maximum per-hour load
    # +capacity+, determines the proportion of hours where demand exceeds
    # production capacity.
    #
    # demand_curve - The "total demand" curve describing total energy demand
    #                throughout the year.
    # capacity     - The total installed capacity, in MWh.
    # excludes     - Producers whose profiled demands should be subtracted from
    #                the total demand curve prior to calculating LOLE. See
    #                merit#123 for an example of why this may be desirable.
    #
    # For example
    #
    #   demand_curve = lole.demand_curve(LoadProfile.new([120, 90, ...]))
    #   lole.expectation(demand_curve, 100)
    #   #
    #   # => 130
    #   #
    #   # This means that for 130 hours in the year, the demand  exceeded
    #   # available supply of 100 MW.
    #
    # Returns a Integer representing the number of hours where capacity was
    # exceeded.
    def expectation(demand_curve, capacity, excludes = [])
      if excludes.any?
        demand_curve -= CurveTools.add_curves(
          excludes.map do |key|
            @order.participants[key].load_curve
          end
        )
      end

      demand_curve.count { |point| point > capacity }
    end

    # Public: Takes the merit order load curve, and multiplies each point by the
    # demand of the converter, yielding the load on the converter over time.
    #
    # An optional +demand+ parameter takes the total demand for the region; if
    # you don't provide a custom-calculated demand, the sum of demands from all
    # Users will be used.
    #
    # Returns an array, each value a Numeric representing the converter demand
    # in a one-hour period.
    def demand_curve(profile, demand = nil)
      Curve.new(profile.to_a) *
        (demand || @order.participants.users.map(&:total_consumption))
    end
  end # LOLE
end # Merit
