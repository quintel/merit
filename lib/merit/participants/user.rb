module Merit

  # The User class holds consumers of electricity. They can be added together
  # to form the 'total demand' for a particular setting of the Merit Order.
  class User < Participant

    attr_reader   :load_profile_key
    attr_accessor :total_consumption

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      super
      @load_profile_key  = opts[:key]
      @total_consumption = opts[:total_consumption]
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    def load_curve
      raise UnknownDemandError unless total_consumption
      LoadCurve.new(load_profile.values.map{ |v| v * total_consumption })
    end

    # Public: returns the LoadProfile of this participant. This basically
    # tells you during what period in a year this technology is used/on.
    def load_profile
      LoadProfile.load(load_profile_key)
    end

  end

end
