# frozen_string_literal: true

module Merit
  # Computes the number of hours in which there is insufficient production to
  # meet demand.
  class Blackout
    def initialize(net_load)
      @net_load = net_load
    end

    def number_of_hours
      @net_load.count { |val| val < -1e-5 }
    end
  end
end
