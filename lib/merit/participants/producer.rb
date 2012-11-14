module Merit

  class Producer < Participant

    attr_reader :full_load_hours,
                :effective_output_capacity, :availability, :number_of_units,
                :marginal_costs, :fixed_costs

    # Public: creates a new participant
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
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    def max_load_curve
      @load_curve ||= LoadCurve.new(load_profile.values.map{ |v| v * total_production })
    end

    # Public: returns the LoadProfile of this participant. This basically
    # tells you during what period in a year this technology is used/on.
    def load_profile
      if load_profile_key
        @load_profile ||= LoadProfile.load(load_profile_key)
      end
    end

    # Public: calculates how much energy is 'produced' by this participant
    #
    # Returns Float: energy in MJ (difference between MWh and MJ is 3600)
    def total_production
      effective_output_capacity * full_load_hours * 3600 * number_of_units
    end

    def available_output_capacity
      effective_output_capacity * availability * number_of_units
    end

    # Public: determined what the max produced load is at a point in time
    def max_load_at(point_in_time)
      if load_profile
        load_profile.values[point_in_time] * total_production
      else
        available_output_capacity
      end
    end
  end
end
