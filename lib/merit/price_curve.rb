# frozen_string_literal: true

module Merit
  # Given a computed Order, determines the price of energy in each point based on which producers
  # and consumers have load.
  class PriceCurve < Curve
    def initialize(order, fallback_price = nil)
      super([], Merit::POINTS, nil)

      @dispatchables = order.participants.dispatchables
      @price_sensitives = order.participants.price_sensitive_users

      # Ensure the fallback price is not lower than the most expensive dispatchable.
      @fallback_price = [
        @dispatchables.last&.cost_strategy&.sortable_cost(nil) || 0.0,
        fallback_price || 3000.0
      ].max
    end

    # Public: Gets the price for the given point in the year.
    #
    # If no price has been explicitly set, the price will be calculated, set, and then returned.
    #
    # Returns a numeric.
    def get(point)
      super || set(point, participant_at(point))
    end

    # Public: Sets the value of the load curve for an point in the year using the price of the given
    # producer.
    #
    # Generally you don't need to call this in your own code; just +get()+ the hour you want and the
    # Curve will set the correct price.
    #
    # Returns the numeric price.
    def set(point, producer)
      if producer.nil?
        super(point, @fallback_price)
      else
        super(point, producer.cost_at(point))
      end
    end

    # Public: Returns the price curve as an array, computing each value if necessary.
    def to_a
      if @values.first.nil?
        # Price curve hasn't been calculated.
        Array.new(@length) { |index| get(index) }
      else
        super
      end
    end

    # Public: Returns which participant is responsible for setting the energy price in a given
    # point.
    #
    # This may return `nil`, indicating that no participant sets the price, likely because all
    # producers are at full capacity.
    def participant_at(point)
      deficit?(point) ? nil : price_sensitive_at(point) || dispatchable_at(point)
    end

    private

    # Internal: Looks for a price-sensitive consumer which may set the energy price. A consumer is
    # price-setting if is is the least expensive consumer and has non-zero load. The cheapest
    # price-sensitive consumer is not price-setting if it is fully-loaded.
    #
    # Returns a Participant or nil if no consumer is price-setting.
    def price_sensitive_at(point)
      return nil if @price_sensitives.empty?

      index = @price_sensitives.rindex { |ps| !ps.load_at(point).zero? }
      user = @price_sensitives[index] if index

      # If the user is completely fulfilled, it means there is extra unused production at the
      # current price, and the producer should determine the price.
      return nil if !user || user.unused_input_capacity_at(point).zero?

      # ... otherwise there is no remaining production at the current price, and there is
      # competition demand-side. The consumer sets the price.
      user
    end

    # Internal: Searches for a dispatchable producer which may set the energy price.
    def dispatchable_at(point)
      index = @dispatchables.rindex { |di| di.load_at(point).positive? }
      index ? @dispatchables[index] : @dispatchables.first
    end

    def deficit?(point)
      last_producer = @dispatchables.last
      last_producer.load_at(point) == last_producer.max_load_at(point)
    end
  end
end
