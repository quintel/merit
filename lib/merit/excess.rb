module Merit
  class Excess
    include NetLoadHelper

    # Public: event_groups
    #
    # Determines a chain of events by calling +number_of_events+ with
    # a range of durations.
    #
    def event_groups(durations = [])
      durations.map do |duration|
        [ duration, number_of_events(duration) ]
      end
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
      @events ||= net_load.values.chunk { |point| point > 1e-10 }.select(&:first)
    end
  end
end
