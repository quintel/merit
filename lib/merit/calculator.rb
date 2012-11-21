module Merit
  # Undertakes the arduous task of calculating the production load for the
  # merit order.
  #
  #   Calculator.new(order).calculate!
  #
  class Calculator

    # Public: Creates a new Calculator which computes the production load for
    # each of the transient producers in the merit order so that demand
    # created by the users is satisfied.
    #
    # order - The Merit::Order instance to be calculated.
    #
    # Returns a Calculator.
    def initialize(order)
      @users     = order.users
      @producers = order.producers
    end

    # Public: Performs the calculation. This sets the load curve# values for
    # each transient producer.
    #
    # Returns true.
    def calculate!
      Merit::POINTS.times do |point|
        export_production_loads_at!(point)
      end

      true
    end

    #######
    private
    #######

    # Internal: For a given +point+ in time, calculates the load which should
    # be handled by transient energy producers, and assigns the calculated
    # values to the producer's load curve.
    #
    # This is the "jumping off point" for calculating the merit order, and
    # note that the method is called once per Merit::POINT. Since Calculator
    # computes a value for every point (default 8,760 of them) even tiny
    # changes can have large effects on the time taken to run the calculation.
    # Therefore, always benchmark / profile your changes!
    #
    # point - The point in time, as an integer. Should be a value between zero
    #         and Merit::POINTS - 1.
    #
    # Returns nothing.
    def export_production_loads_at!(point)
      production_loads = production_loads_at(point)

      # Optimisation: We use #each_with_index despite the fact that #zip would
      # be nicer, since #zip creates a vast amount of intermediate array
      # objects stressing the garbage collector.
      @producers.each_with_index do |producer, index|
        unless producer.always_on?
          producer.load_curve.values[point] = production_loads[index]
        end
      end
    end

    # Internal: Calculates the energy load created by each transient producer
    # according to the merit order.
    #
    # point - The point in time to calculate.
    #
    # Returns an array containing the loads with each value corresponding to
    # a producer in the +@transient+ collection.
    def production_loads_at(point)
      # The total demand for energy at the point in time.
      remaining_load = @users.map{ |user| user.load_at(point) }.reduce(:+)

      max_production_loads_at(point).map do |max_load|
        remaining_load -= max_load

        if max_load < remaining_load
          max_load
        elsif remaining_load < 0.0
          0.0
        else
          remaining_load
        end
      end
    end

    # Internal: Calculates the maximal production for each producer.
    #
    # point - The point in time to calculate.
    #
    # Returns an array of floats.
    def max_production_loads_at(point)
      @producers.map{ |p| p.max_load_at(point) }
    end

  end # Calculator
end # Merit
