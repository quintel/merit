module Merit

  # The User class holds consumers of electricity. They can be added together
  # to form the 'total demand' for a particular setting of the Merit Order.
  class User < Participant

    attr_accessor :total_consumption

    # Public: creates a new participant
    # params opts[Hash] set the attributes
    # returns Participant
    def initialize(opts)
      super
      @total_consumption = opts[:total_consumption]
    end

    # Public: the load curve of a participant, tells us how much energy
    # is produced at what time. It is a product of the load_profile and
    # the total_production.
    # Returns the load in MW
    def load_curve
      raise UnknownDemandError unless total_consumption
      @load_curve ||= LoadCurve.new(load_profile.values.map{ |v| v * total_consumption })
    end

    # Public: returns the LoadProfile of this participant. This basically
    # tells you during what period in a year this technology is used/on.
    def load_profile
      @load_profile ||= LoadProfile.load(key)
    end

    # Public: returns us what the load is for a certain point in time
    def load_at(point_in_time)
      raise UnknownDemandError unless total_consumption
      load_profile.values[point_in_time] * total_consumption
    end

    # Public: What is the total supply between the two given points (inclusive
    # of both points)?
    #
    # start  - The earlier point.
    # finish - The later point.
    #
    # Returns a float.
    def load_between(start, finish)
      count  = 1 + (finish - start)
      values = load_profile.values[start..finish]

      values.reduce(:+) * total_consumption
    end

  end

end
