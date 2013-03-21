module Merit
  
  class Storage < Participant

    attr_accessor :capacity, :max_input, :max_output

    def initialize(opts)
      super
      require_attributes :capacity,
                         :max_input,
                         :max_output

      @capacity   = opts[:capacity]
      @max_input  = opts[:max_input]
      @max_output = opts[:max_output]
    end
  end
end
