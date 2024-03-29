# frozen_string_literal: true

require 'forwardable'

module Merit
  class User
    # A user whose demand is determined by the current price after all other demands have been
    # satisfied.
    #
    # A conditional demand only occurs if the user is willing to pay no more than the price of a
    # dispatchable producer. For example, assumign the User is willing to pay 10, and there are
    # three dispatchbles available with prices of 5, 10, and 15, then the User would be willing to
    # use energy from the first two, but not the third.
    #
    # Conditional demands are not included in the total demand calculated by `DemandCalculator`, and
    # require a separate loop at the end of `Calculator#calculate_point`.

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

      attr_reader :cost_strategy, :group, :load_curve

      # Public: Creates a new `PriceSensitive` which adds price-sensitivity to the given `User`.
      #
      # user          - The `User` being made price sensitive.
      # cost_strategy - A `CostStrategy` instance, describing how to calculate the price the user is
      #                 willing to pay in each hour.
      # group         - Allows the PriceSensitive to be included in a flexibility group.
      #
      # Returns a PriceSensitive.
      def initialize(user, cost_strategy, group = nil)
        raise(IllegalPriceSensitiveUser, user) if user.dependent?

        @inner = user
        @cost_strategy = cost_strategy
        @group = group
        @load_curve = Curve.new(Array.new(Merit::POINTS, 0.0))
      end

      # Public: Offers the price-sensitive an `amount` of energy at a `price`.
      #
      # If the user wishes to purchase some (or all) the energy, it returns the amount, otherwise it
      # returns zero.
      #
      # Returns a numeric.
      def barter_at(point, amount, price)
        # "gt" rather than "gte" so that the participant does not provide energy to itself. This
        # avoids having to do this check explicitly in Calculator avoiding many extra comparisons.
        if @cost_strategy.cost_at(point) > price
          assign_excess(point, amount)
        else
          0.0
        end
      end

      def unused_input_capacity_at(point)
        @inner.load_at(point) - @load_curve[point]
      end

      # Public: Offers the price-sensitive an `amount` of energy.
      #
      # The energy is offered without a price; the energy is surplus to requirements and can
      # therefore be provided to the User regardless of how much it is willing to pay.
      #
      # If the user wishes some (or all) of the energy, it returns the amount. Otherwise it returns
      # zero.
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
      # This allows a PriceSensitive to receive energy from always-on production when there is an
      # excess.
      def flex?
        true
      end

      def user?
        false
      end

      def producer?
        false
      end

      # Public: Price-sensitives consume at the same price as they produce.
      #
      # Returns a CostStrategy.
      def consumption_price
        @cost_strategy
      end

      # Public: The total amount of energy consumed by the user.
      #
      # Defaults to MJ, but may return MWh. For example:
      #
      #   price_sensitive.production
      #   #=> MJ price_sensitive.production(:mwh) # => MWh
      #
      # "production" is a misnomer, but is used for compatibility with other `Participant` classes.
      #
      # Returns a numeric.
      def production(unit = :mj)
        case unit
        when :mj
          @load_curve.sum * 3600
        when :mwh
          @load_curve.sum
        else
          raise "Unknown unit: #{unit}"
        end
      end

      alias_method :total_consumption, :production

      def infinite?
        false
      end

      # Public: Price-sensitive users can consume energy from dispatchable producers (price
      # permitting).
      def consume_from_dispatchables?
        true
      end

      def inspect
        "#<#{self.class.name} #{key} (#{@inner.class.name})>"
      end

      alias_method :to_s, :inspect

      def order=(_); end
    end
  end
end
