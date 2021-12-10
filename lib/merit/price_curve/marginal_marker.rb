# frozen_string_literal: true

module Merit
  class PriceCurve < Curve
    # When a merit order contains optimized storage, the loads of these batteries are represented
    # with always-on producers and curve-based producers. These are not normally price-setting and
    # don't have an explicit price of their own. Rather, they should compete with the marginal
    # producer or consumer.
    #
    # MarginalMarker takes the place of a marignal consumer or producer in PriceCurve when such a
    # battery should set the price.
    class MarginalMarker
      private_class_method :new

      # Public: Creates a MarginalMarker representing a consumer.
      def self.consumer(loaded_hours, other_participants)
        new(loaded_hours, other_participants, :negative?, 0.01)
      end

      # Public: Creates a MarginalMarker representing a producer.
      def self.producer(loaded_hours, other_participants)
        new(loaded_hours, other_participants, :positive?, -0.01)
      end

      def initialize(loaded_hours, other_participants, selector, price_delta)
        @loaded_hours = loaded_hours
        @other_participants = other_participants
        @selector = selector
        @price_delta = price_delta
      end

      # Public: Returns if the producer or consumer is loaded at the given point.
      def active_at?(point)
        @loaded_hours[point]
      end

      # Public: Calculates the cost of the market in the given point.
      def cost_at(point)
        collection = @other_participants.at_point(point)
        index = collection.rindex { |p| p.load_at(point).public_send(@selector) }

        user = index.nil? ? collection.first : collection[index]

        return 0.0 if user.nil?

        user.cost_at(point) + @price_delta
      end
    end
  end
end
