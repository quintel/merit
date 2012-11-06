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

    def load_profile
      @load_profile_values ||= LoadProfile.load(@load_profile_key)
    end

  end

end
