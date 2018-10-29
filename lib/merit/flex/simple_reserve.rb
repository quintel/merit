module Merit
  module Flex
    # A simplified version of Reserve which tracks only the "current" amount of
    # energy stored, without the ability to see how much is stored at each point
    # in time. Decay is not supported.
    #
    # SimpleReserve is able to be used within a calculation to model storage,
    # but cannot be used to reflect upon what happend with storage after the
    # fact.
    class SimpleReserve < Reserve
      def initialize(volume = Float::INFINITY, &decay)
        raise "Decay not supported by #{self.class.name}" if decay

        @volume = volume
        @stored = 0.0
      end

      # Public: Returns how much energy is stored in the reserve at the current
      # calculation frame.
      #
      # Returns a numeric.
      def at(*)
        @stored
      end

      # Public: Sets the `amount` in the reserve in the current calculation
      # frame.
      #
      # Returns the amount.
      def set(_frame, amount)
        @stored = amount
      end

      # Public: Adds the given `amount` of energy in the current calculation
      # frame.
      #
      # Return the amount of energy which was added; note that this may be less
      # than was set in the `amount` parameter.
      def add(_frame, amount)
        if amount + @stored > @volume
          amount = @volume - @stored
          @stored = @volume
        else
          @stored += amount
        end

        amount
      end

      # Public: Takes from the reserve the chosen `amount` of energy in the
      # current calculation frame.
      #
      # Returns the amount of energy subtracted from the reserve. This may be
      # less than you asked for if insufficient was stored.
      def take(_frame, amount)
        if amount > @stored
          amount = @stored
          @stored = 0.0
        else
          @stored -= amount
        end

        amount
      end

      # Public: A human readable version of the reserve for debugging.
      def inspect
        "#<#{self.class.name} volume=#{@volume}>"
      end

      # Public: A human readable version of the reserve.
      def to_s
        "#{self.class.name}(#{@volume})"
      end
    end
  end
end
