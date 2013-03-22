module Merit

  # The Storage within the Merit order is responsible for storing excess
  # of electricity production and for producing electricity if
  # demand is higher that the amount being produced by must-runs and
  # volatile producers.
  class Storage < Participant

    attr_reader :capacity, :max_input, :max_output
    attr_accessor :utilization

    # Public: creates a new storage
    # params opts[Hash] set the attributes
    # returns Storage
    # capacity - is a maximum energy that can be stored in the storage
    # max_input - maximum energy that can be transfered into the storage in a time
    #             unit
    # max_output - maximum energy that can be retrieved from the storage in a time
    #              unit
    # utilization - amount of energy currently stored in the storage
    def initialize(opts)
      super
      require_attributes :capacity,
                         :max_input,
                         :max_output

      @capacity    = opts[:capacity]
      @max_input   = opts[:max_input]
      @max_output  = opts[:max_output]
      @utilization = opts[:utilization] || 0
    end

    def available_capacity
      capacity - utilization
    end
  end
end
