module Merit

  # A participant is a plant or technology that participates in
  # in the Merit Order, such as a coal power plant, a wind turbine
  # or a CHP.
  class Participant
    attr_reader   :key, :load_profile
    attr_accessor :order

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      @opts = opts
      require_attributes :key

      @key = opts[:key]
      @load_profile = opts[:load_profile]
    end

    def to_s
      "#<#{ self.class } #{ key }>"
    end

    alias_method :inspect, :to_s

    # Public: Does the producer have to be running (creating or consuming
    # energy all of the time)?
    #
    # Returns true or false.
    def always_on?
      false
    end

    # Public: The inverse of #always_on?. Determines if this participant may
    # sometimes be turned off.
    def transient?
      ! always_on?
    end

    # Public: Returns the (actual) energy produced by this participant.
    def production(unit = :mj)
      if unit == :mj
        load_curve.sum * 3600
      elsif unit == :mwh
        load_curve.sum
      else
        raise "Unknown unit: #{unit}"
      end
    end

    private

    def require_attributes(*attrs)
      attrs.each do |attr|
        raise MissingAttributeError.new(attr, self.class) unless @opts[attr]
      end
    end
  end # Participant
end # Merit
