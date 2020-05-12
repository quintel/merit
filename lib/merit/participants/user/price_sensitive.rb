# frozen_string_literal: true

require 'forwardable'

module Merit
  class User
    # A user whose demand is determined by the current price after all other
    # demands have been satisfied.
    #
    # A conditional demand only occurs if the user is willing to pay no more
    # than the price of a dispatchable producer. For example, assumign the User
    # is willing to pay 10, and there are three dispatchbles available with
    # prices of 5, 10, and 15, then the User would be willing to use energy from
    # the first two, but not the third.
    #
    # Conditional demands are not included in the total demand calculated by
    # `DemandCalculator`, and require a separate loop at the end of
    # `Calculator#calculate_point`.

    # `PriceSensitive` wraps around a `User`, such that its demand is only
    # satisifed if the price it is willing to pay is less than or equal to the
    # current price of energy.

    # For example, assuming the `PriceSensitive` user is willing to pay 10, and
    # there are three dispatchbles available with prices of 5, 10, and 15, then
    # the User would be willing to use energy from the first two, but not the
    # third.
    #
    # `PriceSensitive` is intentionally _not_ a subclass of `User` and will
    # therefore not be included in `ParticipantSet#users`. It is up to
    # `Calculator` to account for these extra demands.
    class PriceSensitive
      extend Forwardable
      def_delegators :@inner, :key, :group

      attr_reader :group, :load_curve

      # Public: Creates a new `PriceSensitive` which adds price-sensitivity to
      # the given `User`.
      #
      # user        - The `User` being made price sensitive.
      # price_curve - A curve describing the price the user is willing to pay
      #               in each hour.
      # group       - Allows the PriceSensitive to be included in a flexibility
      #               group.
      #
      # Returns a PriceSensitive.
      def initialize(user, price_curve, group = nil)
        raise(IllegalPriceSensitiveUser, user) if user.dependent?

        @inner = user
        @price_curve = price_curve
        @group = group
        @load_curve = Curve.new(Array.new(Merit::POINTS, 0.0))
      end

      # Public: Offers the price-sensitive an `amount` of energy at a `price`.
      #
      # If the user wishes to purchase some (or all) the energy, it returns the
      # amount, otherwise it returns zero.
      #
      # Returns a numeric.
      def barter_at(point, amount, price)
        if @price_curve[point] >= price
          assign_excess(point, amount)
        else
          0.0
        end
      end

      # Public: Offers the price-sensitive an `amount` of energy.
      #
      # The energy is offered without a price; the energy is surplus to
      # requirements and can therefore be provided to the User regardless of
      # how much it is willing to pay.
      #
      # If the user wishes some (or all) of the energy, it returns the amount.
      # Otherwise it returns zero.
      #
      # Returns a numeric.
      def assign_excess(point, amount)
        wants = @inner.load_at(point) - @load_curve[point]

        if wants.positive?
          amount = wants > amount ? amount : wants
          @load_curve[point] += amount

          amount
        else
          0.0
        end
      end

      # Public: Returns the load on the user at the chosen `point`.
      #
      # Returns a numeric.
      def load_at(point)
        @load_curve[point]
      end

      # Public: PriceSensitive is considered flexible.
      #
      # This allows a PriceSensitive to receive energy from always-on production
      # when there is an excess.
      def flex?
        true
      end

      # Public: The total amount of energy consumed by the user.
      #
      # Defaults to MJ, but may return MWh. For example:
      #
      #   price_sensitive.production #=> MJ
      #   price_sensitive.production(:mwh) # => MWh
      #
      # "production" is a misnomer, but is used for compatibility with other
      # `Participant` classes.
      #
      # Returns a numeric.
      def production(unit = :mj)
        if unit == :mj
          @load_curve.sum * 3600
        elsif unit == :mwh
          @load_curve.sum
        else
          raise "Unknown unit: #{unit}"
        end
      end

      def inspect
        "#<#{self.class.name} #{key} (#{@inner.class.name})>"
      end

      alias_method :to_s, :inspect

      def order=(_); end
    end
  end
end
