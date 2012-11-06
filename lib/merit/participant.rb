module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class Participant

    attr_reader :key, :marginal_costs, :capacity, :availability

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      @key            = opts[:key]
      @marginal_costs = opts[:marginal_costs]
      @capacity       = opts[:capacity]
      @availability   = opts[:availability]
    end

  end

end
