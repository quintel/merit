module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class MustRunParticipant < Participant

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
    # Returns Float: energy in MWh
    def total_production
      effective_output_capacity * full_load_hours
    end

  end

end
