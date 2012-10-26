module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class Participant

    attr_reader :key, :type,
                :capacity, :marginal_costs, :availability

    # Public: creates a new participant
    def initialize(opts = nil)
      if opts
        @key               = opts[:key]
        @type              = opts[:type]
        @capacity          = opts[:capacity]
        @marginal_costs    = opts[:marginal_costs]
        @availability      = opts[:availability]
      end
    end

  end

end

