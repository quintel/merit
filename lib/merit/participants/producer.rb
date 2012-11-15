module Merit

  # The Producer within the Merit Order is reponsible for producing electricity
  # to meet demand
  class Producer < Participant

    attr_reader   :effective_output_capacity, :availability,
                  :number_of_units, :marginal_costs, :fixed_costs

    attr_accessor :load_curve

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

      @load_curve                = LoadCurve.new(Array.new(8760))
    end

    # The full load hours are defined as the number of hours that the
    # producer were on AS IF it were producing at the +effective+ output
    # capacity. For any producer with availability < 1, this number is always
    # lower than 8760.
    #
    # When the full load hours were defined as input, this method then returns
    # that number
    def full_load_hours
      if @full_load_hours
        @full_load_hours
      else
        production / ( effective_output_capacity * number_of_units * 3600 )
      end
    end

    # Public: Returns the actual load curve, and this can be set by the
    # merit order object
    def load_curve
      @load_curve
    end

    # Experimental: for demo purposes
    def off_times
      load_curve.values.select{ |v| v == 0 }.size
    end

    # Experimental: for demo purposes
    def ramping_curve
      LoadCurve.new(load_curve.values.each_cons(2).map{ |a,b| (b-a).abs })
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    def max_load_curve
      if load_profile_key
        values = load_profile.values.map { |v| v * max_production }
      else
        values = Array.new(8760, available_output_capacity)
      end
      @max_load_curve ||= LoadCurve.new(values)
    end

    # Experimental: for demo purposes
    def silent_load_curve
      max_load_curve - load_curve
    end

    # Public: returns the LoadProfile of this participant. This basically
    # tells you during what period in a year this technology is used/on.
    def load_profile
      if load_profile_key
        @load_profile ||= LoadProfile.load(load_profile_key)
      end
    end

    # Public: Returns the average load from the load curve
    def average_load
      load_curve.values.reduce(:+) / load_curve.values.size
    end

    # Public: Returns the (actual) energy produced by this producer
    def production
      load_curve.values.reduce(:+) * 3600
    end

    # Public: calculates how much energy is 'produced' by this participant
    #
    # Returns Float: energy in MJ (difference between MWh and MJ is 3600)
    def max_production
      if @full_load_hours
        available_output_capacity * full_load_hours * 3600
      else
        available_output_capacity * 8760 * 3600
      end
    end

    def available_output_capacity
      effective_output_capacity * availability * number_of_units
    end

    # Public: determined what the max produced load is at a point in time
    def max_load_at(point_in_time)
      if load_profile
        load_profile.values[point_in_time] * max_production
      else
        available_output_capacity
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
