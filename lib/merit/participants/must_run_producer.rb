module Merit

  # A Must Run is a plant or technology that participates in
  # in the Merit Order and is always on by definition.
  class MustRunProducer < Producer

    attr_reader :full_load_hours, :load_profile_key

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      super
      @load_profile_key = opts[:load_profile_key]
      @full_load_hours  = opts[:full_load_hours]
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    def load_curve
      LoadCurve.new(load_profile.values.map{ |v| v * total_production })
    end

    # Public: returns the LoadProfile of this participant. This basically
    # tells you during what period in a year this technology is used/on.
    def load_profile
      LoadProfile.load(@load_profile_key)
    end

    # Public: calculates how much energy is 'demanded' by this participant
    #
    # Returns Float: energy in MJ (difference between MWh and MJ is 3600)
    def total_production
      effective_output_capacity * full_load_hours * 3600
    end

  end

end
