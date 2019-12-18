module Merit
  module Flex
    # A simplified version of Reserve which tracks only the "current" amount of
    # energy stored, without the ability to see how much is stored at each point
    # in time.
    #
    # SimpleReserve is able to be used within a calculation to model storage,
    # but cannot be used to reflect upon what happend with storage after the
    # fact.
    class SimpleReserve < Reserve
      def initialize(volume = Float::INFINITY, &decay)
        # raise "Decay not supported by #{self.class.name}" if decay

        @volume = volume
        @stored = 0.0
        @decay = decay
        @last_decay = 0
      end

      # Public: Returns how much energy is stored in the reserve at the current
      # calculation frame.
      #
      # Returns a numeric.
      def at(frame)
        if @decay && @last_decay < frame
          if @stored.positive?
            # More than one frame has passed since last calculating decay. We
            # have to calculate all the missing frames.
            catch_up_decay!(frame - 1) if @last_decay < frame - 1

            @stored -= @decay.call(frame, @stored)
            @stored = 0.0 if @stored.negative?
          end

          @last_decay = frame
        end

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
      def add(frame, amount)
        current = at(frame)

        if amount + current > @volume
          amount = @volume - current
          @stored = @volume
        else
          @stored = current + amount
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

      private

      # Internal: When decay hasn't been calculated for multiple frames, it must
      # catch up with the frame currently being calculated in order to represent
      # the energy lost in the time between the previous calculation and now.
      def catch_up_decay!(frame)
        ((@last_decay + 1)..frame).each do |other_frame|
          at(other_frame)
        end

        @last_decay = frame
      end
    end
  end
end
