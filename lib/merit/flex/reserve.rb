# frozen_string_literal: true

module Merit
  module Flex
    # Stores energy for later use. Has an optional volume which may not be exceeded.
    class Reserve
      def initialize(volume = Float::INFINITY, &decay)
        @volume = volume
        @decay  = decay
        @store  = [0.0]
      end

      # Public: Returns the amount of energy stored in each point.
      #
      # Returns an array.
      def to_a
        @store.dup
      end

      # Public: Returns how much energy is stored in the reserve at the end of the given point. If
      # the technology to which the reserve is attached is still being calculated, the energy stored
      # may be subject to change.
      #
      # Prefer #to_a when you want the stored amount for the fill time period calculated.
      #
      # Returns a numeric.
      def at(point)
        @store[point] ||=
          if point.zero?
            0.0
          else
            fill_blanks!(point)
            at(point - 1) - decay_at(point)
          end
      end

      alias_method :[], :at

      # Public: Sets the `amount` in the reserve for the given `point`. Ignores volume constraints,
      # and assumes you know what you're doing.
      #
      # Returns the amount.
      def set(point, amount)
        @store[point] = amount
      end

      alias_method :[]=, :set

      # Public: Adds the given `amount` of energy in your chosen `point`, ensuring that the reserve
      # does not exceed capacity.
      #
      # Return the amount of energy which was added; note that this may be less than was set in the
      # `amount` parameter.
      def add(point, amount)
        return 0.0 if amount <= 0

        stored = at(point)
        amount = @volume - stored if (stored + amount) > @volume

        set(point, stored + amount)

        amount
      end

      # Public: Returns how much of the reserve is unfilled.
      #
      # Returns a numeric.
      def unfilled_at(point)
        @volume - at(point)
      end

      # Public: Takes from the reserve the chosen `amount` of energy.
      #
      # Returns the amount of energy subtracted from the reserve. This may be less than you asked
      # for if insufficient was stored.
      def take(point, amount)
        return 0.0 if amount <= 0

        stored = at(point)

        if stored > amount
          set(point, at(point) - amount)
          amount
        else
          set(point, 0.0)
          stored
        end
      end

      # Public: Returns how much energy decayed in the reserve at the beginning of the given point.
      #
      # Returns a numeric.
      def decay_at(point)
        return 0.0 if point.zero? || !@decay

        start = at(point - 1)

        return 0.0 if start.zero?

        decay = @decay.call(point, start)

        decay < start ? decay : start
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

      # Internal: Fills the value of any `nil` points in the reserve up to the given point.
      #
      # If there are large numbers of points in the reserve for which there is no value, compute
      # them iteratively rather than recursively to avoid consuming excessive stack space
      # (quintel/etmodel#2296).
      #
      # Returns nothing
      def fill_blanks!(point)
        return if point.zero?

        if @store.empty?
          # 5-10 times faster than next branch.
          @store = Array.new(point - 1, 0.0)
        elsif point > @store.length
          @store.length.upto(point - 1) { |past| at(past) }
        end
      end
    end
  end
end
