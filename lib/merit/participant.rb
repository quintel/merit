module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class Participant

    attr_reader :key,
                :effective_output_capacity, :availability, :number_of_units,
                :marginal_costs, :fixed_costs

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      raise MissingAttributeError.new('key',self.class) unless opts[:key]
      @key                       = opts[:key]
      @marginal_costs            = opts[:marginal_costs]
      @effective_output_capacity = opts[:effective_output_capacity]
      @availability              = opts[:availability]
      @number_of_units           = opts[:number_of_units]
      @fixed_costs               = opts[:fixed_costs]
    end

  end

end
