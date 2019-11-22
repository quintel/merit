module Merit
  class User < Participant
    class << self
      protected :new

      # Public: Creates an appropriate User for the options given. The options
      # hash should include a :total_consumption key if you want to express the
      # User's total energy use for the year, or a :load_curve if the per-point
      # consumption defined using a Curve.
      #
      # Returns a Participant.
      def create(options)
        if options.key?(:total_consumption)
          TotalConsumption.new(options)
        elsif options.key?(:load_curve)
          WithCurve.new(options)
        else
          raise UnknownDemandError
        end
      end
    end # class << self

    attr_reader :load_curve

    # Public: Returns the load on the participant for a certain point in time.
    def load_at(point_in_time)
      @load_curve.values[point_in_time]
    end

    # Public: What is the total supply between the two given points (inclusive
    # of both points)?
    #
    # start  - The earlier point.
    # finish - The later point.
    #
    # Returns a float.
    def load_between(start, finish)
      @load_curve.values[start..finish].reduce(:+)
    end
  end # User
end # Merit
