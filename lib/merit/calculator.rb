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
      producers  = order.producers

      # Not using Enumerable#partition allows us to quickly test that all the
      # always-on producers were before the first transient producer.
      partition  = producers.index(&:transient?) || producers.length - 1

      @always_on = producers[0...partition]
      @transient = producers[partition..-1] || []

      if @transient.any?(&:always_on?)
        raise Merit::IncorrectProducerOrder.new
      end
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
      # The total demand for energy at the point in time.
      remaining = @users.map { |user| user.load_at(point) }.reduce(:+)

      # Optimisation: This is order-dependent; it requires that always-on
      # producers are before the transient producers, otherwise "remaining"
      # load will not be correct.
      #
      # Since this method is called a lot, being able to handle always-on and
      # transient producers in separate loops allows us to skip calling
      # #always_on? in every iteration. This accounts for a 20% reduction in
      # the calculation runtime.

      @always_on.each do |producer|
        remaining -= producer.max_load_at(point)
      end

      @transient.each do |producer|
        max_load   = producer.max_load_at(point)
        remaining -= max_load

        producer.load_curve.values[point] = if max_load < remaining
          max_load
        elsif remaining > 0.0
          remaining
        else
          0.0
        end
      end
    end

  end # Calculator
end # Merit
