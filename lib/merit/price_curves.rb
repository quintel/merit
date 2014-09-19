module Merit
  # Price curves determine how electricity is priced in each hour of the year.
  module PriceCurves
    # FirstUnloaded will price electricity by taking the price of the first
    # producer to have no load, or by incrementing the load of a cost-function
    # producer equivalent to adding one extra plant.
    #
    # In the event that all producers are fully-loaded, a fallback price is
    # determined by multiplying the price of the most expensive producer by a
    # constant.
    class FirstUnloaded < Curve
      # The amount by which to multiply the most expensive producer when all are
      # fully-loaded.
      #
      # See quintel/merit#66 for the rationale behind this constant.
      FALLBACK_MULTIPLIER = 7.22

      # Public: Creates a new price curve for the given merit order.
      def initialize(order)
        super([], Merit::POINTS, nil)
        @order = order
      end

      # Public: Sets the value of the load curve for an point in the year using
      # the price of the given producer.
      #
      # Generally you don't need to call this in your own code; just +get()+ the
      # hour you want and the Curve will set the correct price.
      #
      # Returns the numeric price.
      def set(point, producer)
        if producer.nil?
          super(point, fallback_price(point))
        else
          super(point, price_of(producer, point))
        end
      end

      # Public: Gets the price for the given point in the year.
      #
      # If no price has been explicitly set, the price will be calculated, set,
      # and then returned.
      #
      # Returns a numeric.
      def get(point)
        super || set(point, producer_at(point))
      end

      # Public: Returns the Producer responsible for setting the price in the
      # given +point+.
      def producer_at(point)
        @order.participants.dispatchables
          .select { |producer| producer.cost_strategy.price_setting?(point) }
          .min_by { |producer| producer.cost_strategy.sortable_cost(point) }
      end

      #######
      private
      #######

      # Internal: Determines the price which should be used in the event that
      # all producers are fully-loaded.
      #
      # Returns a numeric.
      def fallback_price(point)
        if fallback = fallback_producer(point)
          price_of(fallback, point, true) * FALLBACK_MULTIPLIER
        else
          600.0
        end
      end

      # Internal: calculates the price of a producer in the given point of the
      # year.
      #
      # If allow_loaded is false, and the producer is not price-setting (see
      # CostStrategy::Base#price_setting?), an InsufficientCapacityForPrice
      # exception will be raised.
      #
      # Returns a numeric.
      def price_of(producer, point, allow_loaded = false)
        producer.price_at(point, allow_loaded)
      end

      # Internal: Returns the producer which should be used to calculate the
      # price in the event that all producers are fully-loaded.
      def fallback_producer(point)
        @order.participants.dispatchables.reverse_each.detect do |producer|
          producer.number_of_units > 0
        end
      end
    end

    # LastLoaded calculates electricity prices by using the cost of the most
    # expensive producer which has load assigned.
    class LastLoaded < FirstUnloaded
      def initialize(*)
        super
        @dispatchables = @order.participants.dispatchables
      end

      # Public: Returns the Producer responsible for setting the price in the
      # given +point+.
      def producer_at(point)
        max_cost     = -1.0
        max_producer = nil

        # This is faster than reject/max_by, and avoids creating an array.
        @dispatchables.each do |producer|
          next if producer.load_at(point).zero?

          cost = producer.cost_at(point)

          if cost > max_cost
            max_cost     = cost
            max_producer = producer
          end
        end

        max_producer ? max_producer : @dispatchables.first
      end

      #######
      private
      #######

      def fallback_producer(point)
        @dispatchables.reverse_each.detect do |producer|
          producer.load_at(point).zero?
        end
      end

      def price_of(producer, point, *)
        producer.cost_at(point)
      end
    end # LastLoaded
  end # PriceCurves
end # Merit
