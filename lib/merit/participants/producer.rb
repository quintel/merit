module Merit

  # The Producer within the Merit Order is reponsible for producing electricity
  # to meet demand
  class Producer < Participant

    include Profitable

    attr_accessor :load_curve, :load_profile, :position

    attr_reader   :output_capacity_per_unit, :availability, :number_of_units,
                  :fixed_costs_per_unit, :fixed_om_costs_per_unit,
                  :full_load_hours, :cost_strategy

    # Public: creates a new producer
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      super

      @full_load_hours           = opts[:full_load_hours]
      @output_capacity_per_unit  = opts[:output_capacity_per_unit]
      @availability              = opts[:availability]
      @number_of_units           = opts[:number_of_units]
      @fixed_costs_per_unit      = opts[:fixed_costs_per_unit]
      @fixed_om_costs_per_unit   = opts[:fixed_om_costs_per_unit]

      @load_curve    = Curve.new([], Merit::POINTS)
      @cost_strategy = CostStrategy.create(self, opts)
    end

    # Public: The cost for the producer to output a MW. This may be a constant,
    # or it may vary depending on what times of the year the producer is active,
    # or the amount of energy it outputs.
    #
    # This method may not be called prior to calculation of the merit order; if
    # you need a value to sort the producers, use +cost_strategy.sortable_cost+
    # instead.
    #
    # Returns a Numeric.
    def marginal_costs
      @cost_strategy.marginal_cost
    end

    # Public: Tells you what the producer would cost if it were the
    # price-setting producer for a particular +point+ in the merit order.
    #
    # point        - The hour of the year in which to look up the price.
    #
    # allow_loaded - If the producer has insufficient remaining capacity to be
    #                price setting, it will raise InsufficentCapacityForPrice.
    #                Set +allow_loaded+ to be true if you wish to skip this
    #                check, and know the price of the producer even if it isn't
    #                price-setting.
    #
    # Returns a numeric.
    def price_at(point, allow_loaded = false)
      @cost_strategy.price_at(point, allow_loaded)
    end

    # Public: Tells you the actual marginal cost of a plant operating at a
    # specific hour in the year. Accurate costs for cost-function producers
    # require the merit order to have been calculated -- and loads set -- before
    # requesting the cost.
    #
    # point - The hour of the year in which to look up the cost.
    #
    # Returns a numeric.
    def cost_at(point)
      @cost_strategy.cost_at(point)
    end

    # Public: Tells you the load on the producer for a given hour in the year.
    # Assumes that the merit order has been calculated.
    #
    # point - The hour of the year in which to look up the cost.
    #
    # Returns a numeric.
    def load_at(point)
      @load_curve.get(point)
    end

    # Public: Tells you if this producer's marginal cost is a price (the final
    # price charged to the region), rather than a cost.
    #
    # A good example is an interconnect, where the cost is in fact a price
    # charged by a foreign nation.
    #
    # Returns true or false.
    def provides_price?
      false
    end

    # Public: Sets a load on the producer.
    #
    # Returns the load.
    def set_load(point, amount)
      load_curve.set(point, amount)
    end

    # The full load hours are defined as the number of hours that the
    # producer were on AS IF it were producing at the +effective+ output
    # capacity. For any producer with availability < 1, this number is always
    # lower than 8760.
    #
    # When the full load hours were defined as input, this method then returns
    # that number
    def full_load_hours
      @full_load_hours ||
        if output_capacity_per_unit.zero? || number_of_units.zero?
          0.0
        else
          production / (output_capacity_per_unit * number_of_units * 3600)
        end
    end

    # Public: Returns the actual load curve, and this can be set by the
    # merit order object
    def load_curve
      if always_on?
        max_load_curve
      else
        @load_curve
      end
    end

    # Public: Returns the number of times that the Producer is completely off
    def off_times
      load_curve.select{ |v| v == 0 }.size
    end

    # Public: Returns a Curve with the absolute increase/decrease of power from
    # one hour to the next
    def ramping_curve
      Curve.new(load_curve.each_cons(2).map{ |a,b| (b-a).abs })
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    def max_load_curve
      if @load_profile
        values = @load_profile.values.map { |v| v * max_production }
      else
        values = Array.new(Merit::POINTS, available_output_capacity)
      end

      @max_load_curve ||= Curve.new(values)
    end

    # Public: Returns a Curve with the difference between the max and the actual
    # load used.
    def spare_load_curve
      max_load_curve - load_curve
    end

    # Public: Returns the average load from the load curve
    def average_load
      load_curve.reduce(:+) / load_curve.length
    end

    # Public: Returns the (actual) energy produced by this producer
    def production(unit = :mj)
      if unit == :mj
        load_curve.reduce(:+) * 3600
      elsif unit == :mwh
        load_curve.reduce(:+)
      else
        raise "Unknown unit: #{unit}"
      end
    end

    # Public: calculates how much energy is 'produced' by this participant
    #
    # Returns Float: energy in MJ (difference between MWh and MJ is 3600)
    def max_production
      @max_production ||= if @full_load_hours
        # NOTE: effective output capacity must be used here because availability
        # has been taken into account when providing the full_load_hours
        output_capacity_per_unit * full_load_hours * number_of_units * 3600
      else
        # Available output capacity time seconds in a year takes into account
        # that producers have some time that they are unavailable
        available_output_capacity * 8760 * 3600
      end
    end

    def available_output_capacity
      @available_output_capacity ||=
        output_capacity_per_unit * availability * number_of_units
    end

    # Public: determined what the max produced load is at a point in time
    def max_load_at(point_in_time)
      if @load_profile
        @load_profile.values[point_in_time] * max_production
      else
        available_output_capacity
      end
    end

    # Public: What is the total demand between the two given points (inclusive
    # of both points)?
    #
    # start  - The earlier point.
    # finish - The later point.
    #
    # Returns a float.
    def load_between(start, finish)
      if @load_profile
        @load_profile.values[start..finish].reduce(:+) * max_production
      else
        available_output_capacity * (1 + (finish - start))
      end
    end

    # Public: All the information you want in your terminal!
    def info
      puts <<EOF
=================================================================================
Key:   #{key}
Class: #{self.class}

#{load_curve.draw if load_curve}
                       LOAD CURVE (x = time, y = MW)
                       Min: #{load_curve.min}, Max: #{load_curve.max}
                       SD: #{load_curve.sd}

Summary:
--------
Full load hours:           #{full_load_hours} hours

Production:                #{production / 10**9} PJ
Max Production:            #{max_production / 10**9} PJ

Average load:              #{average_load} MW
Available_output_capacity: #{available_output_capacity} MW

Number of units:           #{number_of_units} number of (typical) plants
output_capacity_per_unit:  #{output_capacity_per_unit} (MW)
Availability:              #{availability} (fraction)

EOF
      true
    end
  end
end
