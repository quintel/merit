# frozen_string_literal: true

module Merit
  module Flex
    # A simplified version of Reserve which disallows random access to most
    # methods (such as set, add, and take).
    #
    # These methods may be called only during the Merit::Calculator run.
    # Calling these methods at any other time results in undefined behavior.
    #
    # This class is rougly twice as fast as Reserve and should be used when
    # you only require the use of Reserve as part of anther technology --
    # such as Flex::Storage -- and the only access to the Reserve after the
    # calculation will be `to_a`.
    class SimpleReserve < Reserve
      def initialize(volume = Float::INFINITY, &decay)
        super

        @stored = 0.0
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

        @store[frame] = @stored unless @store[frame]

        @store[frame]
      end

      # Public: Sets the `amount` in the reserve in the current calculation
      # frame.
      #
      # Returns the amount.
      def set(frame, amount)
        @stored = amount
        @store[frame] = amount
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

        @store[frame] = @stored

        amount
      end

      # Public: Takes from the reserve the chosen `amount` of energy in the
      # current calculation frame.
      #
      # Returns the amount of energy subtracted from the reserve. This may be
      # less than you asked for if insufficient was stored.
      def take(frame, amount)
        if amount > @stored
          amount = @stored
          @stored = 0.0
        else
          @stored -= amount
        end

        @store[frame] = @stored

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
