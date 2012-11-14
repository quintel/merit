module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class Participant

    attr_reader :key, :load_profile_key

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      raise MissingAttributeError.new('key',self.class) unless opts[:key]
      @key              = opts[:key]
      @load_profile_key = opts[:load_profile_key]
    end

    def to_s
      "<#{self.class} #{key}>"
    end

  end

end
