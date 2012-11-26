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

    # Public: Performs the calculation. This sets the load curve values for
    # each transient producer.
    #
    # Returns true.
    def calculate!
      Merit::POINTS.times do |point|
        each_production_load_at(point) do |producer, value|
          producer.load_curve.set(point, value)
        end
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
    def each_production_load_at(point)
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
        max_load = producer.max_load_at(point)

        # Optimisation: Load points default to zero, skipping to the next
        # iteration is faster then running the comparison / load_curve#set.
        next if max_load.zero?

        if max_load < remaining
          yield producer, max_load
        elsif remaining > 0.0
          yield producer, remaining
        else
          # Optimisation: If all of the demand has been accounted for, there
          # is no need to waste time with further iterations and expensive
          # calls to Producer#max_load_at.
          break
        end

        # Subtract the production of the producer from the demand
        remaining -= max_load
      end
    end
  end # Calculator

  # A calculator which skips points in order to compute the result faster.
  #
  # This works on the principle that days which are close to one another are
  # expected to have very similar load characteristics; it is unlikely that
  # wind turbines will be in high demand on January 1st, but low demand on the
  # following day.
  #
  # This calculator computes only a subset of days in the year, and then
  # copies the results for those days into the following few days. For
  # example, with a resolution of 3, it will compute the results for January
  # 1st, then use the same figures for January 2nd and 3rd. January 4th will
  # then be computed, with its values being used for the 5th and 6th.
  #
  # The result is that we're able to skip a large number of extra calculations
  # with only a very small loss of accuracy. "Freak occurrences" in the load
  # curves (such as an unusually high load in one particular hour, on one day
  # of the year) may be lost or exaggerated depending on whether they happen
  # on a computed day, but the overall long-term trends remain.
  class QuantizingCalculator < Calculator
    # The number of points in each day.
    PER_DAY = Merit::POINTS / 365

    # Public: Creates a new SamplingCalculator which computes the production
    # load for each of the transient producers in a way which is faster -- but
    # less accurate than -- the ordinary Calculator.
    #
    # order      - The Merit::Order instance to be calculated.
    # chunk_size - How many days should be in each calculated "chunk". Lower
    #              numbers result in a more accurate calculation at the
    #              expense of performance.
    #
    # Returns a Calculator.
    def initialize(order, chunk_size = 8)
      if chunk_size.nil? || chunk_size == 1
        raise InvalidChunkSize.new(chunk_size)
      end

      super(order)
      @chunk_size = chunk_size
    end

    # Public: Performs the calculation. This sets the load curve values for
    # each transient producer.
    #
    # Returns true.
    def calculate!
      # The point being computed.
      point = 0

      # How many points in total are computed each time we compute a day.
      each_day = @chunk_size * PER_DAY

      # The number of points by which we increment when we have finished
      # computing a full day.
      day_incr = each_day - PER_DAY

      while point < Merit::POINTS
        each_production_load_at(point) do |producer, value|
          @chunk_size.times do |position|
            # Don't set values beyond Dec 24th @ 23:00.
            if (future_point = (position * PER_DAY) + point) < Merit::POINTS
              producer.load_curve.set(future_point, value)
            end
          end
        end

        # Is this the end of the day (skip fowards), or are there still points
        # left to be calculated for the current day?
        point += (point % each_day == (PER_DAY - 1)) ? day_incr : 1
      end
    end
  end # QuantizingCalculator
end # Merit
