# frozen_string_literal: true

module Merit
  # Computes the number of hours in which there is insufficient production to
  # meet demand, plus the volume and peak of those shortfalls.
  class Blackout
    EPSILON = 1e-5

    def initialize(net_load)
      @net_load = net_load
    end

    # Number of hours with a shortfall
    def number_of_hours
      @net_load.count { |val| val < -EPSILON }
    end

    # Total volume of shortfall (sum of all deficits)
    def volume
      @net_load
        .select { |val| val < -EPSILON }    # only deficit hours
        .sum     { |val| -val }             # flip sign and sum
    end

    # Peak hourly shortfall (the largest single-hour deficit)
    def peak
      minimum = @net_load.min                # most negative value
      minimum < -EPSILON ? -minimum : 0.0      # if it’s a deficit, flip sign; otherwise return zero
    end
  end
end
