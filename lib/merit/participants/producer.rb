module Merit

  # The Producer within the Merit Order is reponsible for producing electricity
  # to meet demand
  class Producer < Participant

    attr_reader   :effective_output_capacity, :availability,
                  :number_of_units, :marginal_costs, :fixed_costs

    attr_accessor :load_curve, :load_profile

    # Public: creates a new producer
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      super

      @full_load_hours           = opts[:full_load_hours]
      @marginal_costs            = opts[:marginal_costs]
      @effective_output_capacity = opts[:effective_output_capacity]
      @availability              = opts[:availability]
      @number_of_units           = opts[:number_of_units]
      @fixed_costs               = opts[:fixed_costs]

      @load_curve   = LoadCurve.new([], Merit::POINTS)
      @load_profile = load_profile_key && LoadProfile.load(load_profile_key)
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
        if effective_output_capacity.zero? || number_of_units.zero?
          0.0
        else
          production / (effective_output_capacity * number_of_units * 3600)
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

    # Experimental: for demo purposes
    def off_times
      load_curve.select{ |v| v == 0 }.size
    end

    # Experimental: for demo purposes
    def ramping_curve
      LoadCurve.new(load_curve.each_cons(2).map{ |a,b| (b-a).abs })
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

      @max_load_curve ||= LoadCurve.new(values)
    end

    # Experimental: for demo purposes
    def silent_load_curve
      max_load_curve - load_curve
    end

    # Public: Returns the average load from the load curve
    def average_load
      load_curve.reduce(:+) / load_curve.length
    end

    # Public: Returns the (actual) energy produced by this producer
    def production
      load_curve.reduce(:+) * 3600
    end

    # Public: calculates how much energy is 'produced' by this participant
    #
    # Returns Float: energy in MJ (difference between MWh and MJ is 3600)
    def max_production
      @max_production ||= if @full_load_hours
        # NOTE: effective output capacity must be used here because availability
        # has been taken into account when providing the full_load_hours
        effective_output_capacity * full_load_hours * number_of_units * 3600
      else
        # Available output capacity time seconds in a year takes into account
        # that producers have some time that they are unavailable
        available_output_capacity * 8760 * 3600
      end
    end

    def available_output_capacity
      @available_output_capacity ||=
        effective_output_capacity * availability * number_of_units
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
                       Min: #{load_curve.values.min}, Max: #{load_curve.values.max}
                       SD: #{load_curve.sd}

Summary:
--------
Full load hours:           #{full_load_hours} hours

Production:                #{production / 10**9} PJ
Max Production:            #{max_production / 10**9} PJ

Average load:              #{average_load} MW
Available_output_capacity: #{available_output_capacity} MW

Number of units:           #{number_of_units} number of (typical) plants
Effective_output_capacity: #{effective_output_capacity} (MW)
Availability:              #{availability} (fraction)


#{}
EOF
    end
  end
end
