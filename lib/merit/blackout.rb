module Merit
  class Blackout
    include NetLoadHelper

    def number_of_hours
      net_load.count { |val| val < -1e-5 }
    end
  end
end
