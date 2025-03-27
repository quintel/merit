# frozen_string_literal: true

module Merit
  # Given a computed Order, determines the price of energy in each point based on which producers
  # and consumers have load.
  class PriceCurve < Curve
    def initialize(order, fallback_price = nil)
      super([], Merit::POINTS, nil)

      @dispatchables = Sorting.by_sortable_cost(order.participants.dispatchables)
      @net_load = order.net_load

      @price_sensitives =
        Sorting.by_consumption_price_desc(order.participants.price_sensitive_users)

      # Ensure the fallback price is not lower than the most expensive dispatchable.
      @fallback_price = [fallback_price || 3000.0].max
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
      case producer
      when :deficit, nil
        super(
          point,
          [
            @fallback_price,
            last_available_dispatchable(point)&.cost_strategy&.cost_at(point)
          ].compact.max
        )
      when :surplus
        super(point, 0.0)
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
      deficit?(point) ? :deficit : price_sensitive_at(point) || dispatchable_at(point) || :surplus
    end

    private

    # Internal: Looks for a price-sensitive consumer which may set the energy price. A consumer is
    # price-setting if is is the least expensive consumer and has non-zero load. The cheapest
    # price-sensitive consumer is not price-setting if it is fully-loaded.
    #
    # Returns a Participant or nil if no consumer is price-setting.
    def price_sensitive_at(point)
      return nil if @price_sensitives.empty?

      collection = @price_sensitives.at_point(point)

      index = collection.rindex { |ps| ps.load_at(point).negative? && ps.price_setting?(point) }
      user = collection[index] if index

      # If the user is completely fulfilled, it means there is extra unused production at the
      # current price, and the producer should determine the price.
      return nil if !user || user.unused_input_capacity_at(point).zero?

      # ... otherwise there is no remaining production at the current price, and there is
      # competition demand-side. The consumer sets the price.
      user
    end

    # Internal: Searches for a dispatchable producer which may set the energy price.
    def dispatchable_at(point)
      collection = @dispatchables.at_point(point)
      index = collection.rindex { |di| di.load_at(point).positive? }

      index && collection[index]
    end

    def deficit?(point)
      @net_load[point] < -1e-5
    end

    # Internal: Returns the most expensive dispatchable which has non-zero possible load at the
    # given point.
    #
    # Returns a Producer or nil if no dispatchables are available.
    def last_available_dispatchable(point)
      dispatchables = @dispatchables.at_point(point)

      dispatchables.reverse_each do |producer|
        return producer if producer.max_load_at(point).positive?
      end

      nil
    end
  end
end
