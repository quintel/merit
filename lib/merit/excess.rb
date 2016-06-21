module Merit
  class Excess
    def initialize(order)
      @order = order
    end

    # Public: number_of_events
    #
    # Given a duration in hours, this method determines the amount of times
    # production exceeds consumption by the specified duration.
    #
    def number_of_events(duration)
      events.inject(0) do |result, (_, streak)|
        result + (streak.size >= duration ? 1 : 0)
      end
    end

    private

    def events
      @events ||= net_load.values.chunk { |point| point > 0 }.select(&:first)
    end

    def net_load
      production - consumption
    end

    def production
      @order.participants.producers.map(&:load_curve).reduce(:+)
    end

    def consumption
      @order.participants.users.map(&:load_curve).reduce(:+)
    end
  end
end
