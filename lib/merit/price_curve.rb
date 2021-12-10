# frozen_string_literal: true

require_relative './price_curve/marginal_marker'

module Merit
  # Given a computed Order, determines the price of energy in each point based on which producers
  # and consumers have load.
  class PriceCurve < Curve
    def initialize(order, fallback_price = nil)
      super([], Merit::POINTS, nil)

      @dispatchables = Sorting.by_sortable_cost(order.participants.dispatchables)

      @price_sensitives =
        Sorting.by_consumption_price_desc(order.participants.price_sensitive_users)

      @inflex_consumer_marker = inflexible_consumption_marker(order)
      @inflex_producer_marker = inflexible_production_marker(order)

      # Ensure the fallback price is not lower than the most expensive dispatchable.
      @fallback_price = [
        order.participants.dispatchables.last&.cost_strategy&.sortable_cost(nil) || 0.0,
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
      case producer
      when :deficit, nil then super(point, @fallback_price)
      when :surplus      then super(point, 0.0)
      else                    super(point, producer.cost_at(point))
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
      return :deficit if deficit?(point)

      ps = price_sensitive_at(point)

      return ps if ps && ps != @inflex_consumer_marker

      # Price-sensitives are always price-setting, except when they are the always-on price-marker,
      # in which case a dispatchable may be price setting if it is more expensive.

      di = dispatchable_at(point)

      return :surplus if ps.nil? && di.nil?

      return di if ps.nil?
      return ps if di.nil?

      ps.cost_at(point) > di.cost_at(point) ? ps : di
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

      index = collection.rindex { |ps| ps.load_at(point).negative? }
      user = collection[index] if index

      if user.nil? && @inflex_consumer_marker&.active_at?(point)
        # No price-setting consumers, but the order has an always-on consumer which sets the price.
        return @inflex_consumer_marker
      end

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

      if index.nil? && @inflex_producer_marker&.active_at?(point)
        # No dispatchable is price setting, but an always on producer may set the price.
        return @inflex_producer_marker
      end

      index && collection[index]
    end

    def deficit?(point)
      last_producer = @dispatchables.at_point(point).last
      last_producer.load_at(point) == last_producer.max_load_at(point)
    end

    # When the merit order contains one or more inflexible consumers which are allowed to set a
    # price, we return a marker object which instructs the price curve to use this to set the price
    # when appropriate.
    def inflexible_consumption_marker(order)
      # Can't set a price if there are no price-sensitives.
      return nil if @price_sensitives.empty?

      priced_inflexibles = order.participants.users.select(&:provides_price?)

      return nil unless priced_inflexibles.any?

      loaded_hours = Array.new(Merit::POINTS, false)

      Merit::POINTS.times do |point|
        loaded_hours[point] = priced_inflexibles.any? { |inflex| inflex.load_at(point)&.positive? }
      end

      MarginalMarker.consumer(loaded_hours, @price_sensitives)
    end

    # When the merit order contains one or more inflexible consumers which are allowed to set a
    # price, we return a marker object which instructs the price curve to use this to set the price
    # when appropriate.
    def inflexible_production_marker(order)
      # Can't set a price if there are no dispatchables.
      return nil if @dispatchables.empty?

      priced_inflexibles = order.participants.always_on.select(&:provides_price?)

      return nil unless priced_inflexibles.any?

      loaded_hours = Array.new(Merit::POINTS, false)

      Merit::POINTS.times do |point|
        loaded_hours[point] = priced_inflexibles.any? { |inflex| inflex.load_at(point)&.positive? }
      end

      MarginalMarker.producer(loaded_hours, @dispatchables)
    end
  end
end
