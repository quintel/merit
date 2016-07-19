module Merit
  class Excess
    include NetLoadHelper

    # Public: Determines the total number of excess events.
    #
    # Returns an integer.
    def total_number_of_events
      net_load.count(&over_producing)
    end

    # Public: Determines a chain of events by calling +number_of_events+ with
    # a range of durations.
    def event_groups(durations = [])
      durations.map do |duration|
        [ duration, number_of_events(duration) ]
      end
    end

    # Public: Determines the amount of times production exceeds consumption
    # by the specified duration.
    #
    # duration - Length of event
    #
    # Returns an integer
    def number_of_events(duration)
      events.inject(0) do |result, (_, streak)|
        result + (streak.size >= duration ? 1 : 0)
      end
    end

    private

    def over_producing
      -> (point) { point > 1e-10 }
    end

    def events
      @events ||= net_load.values.chunk(&over_producing).select(&:first)
    end
  end
end
