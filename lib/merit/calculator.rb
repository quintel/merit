module Merit
  # Undertakes the arduous task of calculating the production load for the
  # merit order.
  #
  #   Calculator.new.calculate(order)
  #
  # Terminology:
  #
  #   "always-on"  - Producers which must always be running, and therefore
  #                  demand / load is assigned to these first.
  #
  #   "transients" - The opposite of an always-on producer, these may be
  #                  turned on and off as necessary in order to fulfil any
  #                  demand which cannot be provided by an always-on producer.
  #
  class Calculator
    # Public: Performs the calculation. This sets the load curve values for
    # each transient producer.
    #
    # order - The Merit::Order instance to be calculated.
    #
    # Returns self.
    def calculate(order)
      order.participants.lock!
      producers = order.participants.producers_for_calculation

      each_point { |point| compute_point(order, point, producers) }

      self
    end

    #######
    private
    #######

    # Internal: Yields each point for which loads should be calcualted.
    #
    # This can be overridden in subclass if you want to calculate only a
    # subset of the points.
    #
    # Returns nothing.
    def each_point
      Merit::POINTS.times { |point| yield point }
    end

    # Internal: This is called with a +producer+, +point+, and +value+ each
    # time +calculate+ computes a value for a transient producer.
    #
    # Combined with +each_point+, subclasses can override this to compute only
    # a subset of the points
    #
    # Returns nothing.
    def assign_load(producer, point, value)
      producer.set_load(point, value)
    end

    # Internal: Computes the total energy demand for a given +point+.
    #
    # order - The merit order.
    # point - The point in time.
    #
    # Returns a float.
    def demand(order, point)
      # The total demand for energy at the point in time.
      order.participants.users.map { |u| u.load_at(point) }.reduce(:+) || 0.0
    end

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
    # order     - The Merit::Order being calculated.
    # point     - The point in time, as an integer. Should be a value between
    #             zero and Merit::POINTS - 1.
    # producers - An object supplying the always_on and transient producers.
    #
    # Returns nothing.
    def compute_point(order, point, producers)
      # Optimisation: This is order-dependent; it requires that always-on
      # producers are before the transient producers, otherwise "remaining"
      # load will not be correct.
      #
      # Since this method is called a lot, being able to handle always-on and
      # transient producers in separate loops allows us to skip calling
      # #always_on? in every iteration. This accounts for a 20% reduction in
      # the calculation runtime.

      if (remaining = demand(order, point)) < 0
        raise SubZeroDemand.new(point, remaining)
      end

      flex = producers.flex

      producers.always_on(point).each do |producer|
        produced = producer.max_load_at(point)

        if produced > remaining
          # The producer has enough to meet demand, and then have some left
          # over for flex consumption.
          produced -= remaining
          remaining = 0.0

          if produced > 0
            flex.each do |tech|
              produced -= tech.assign_excess(point, produced)

              # If there is no energy remaining to be assigned we can exit early
              # and, as an added bonus, prevent assigning tiny negatives
              # resulting from floating point errors, which messes up
              # technologies which have a Reserve with volume 0.0.
              break if produced <= 1e-11
            end
          end

          break if produced > 0
        elsif produced < remaining
          # The producer is emitting less energy that demanded. Take it all and
          # continue with the next producer.
          remaining -= produced
        end

        remaining = 0.0 if remaining < 0.0
      end

      producers.transients(point).each do |producer|
        max_load = producer.max_load_at(point)

        # Optimisation: Load points default to zero, skipping to the next
        # iteration is faster then running the comparison / load_curve#set.
        next if max_load.zero?

        if max_load < remaining
          assign_load(producer, point, max_load)
        else
          assign_load(producer, point, remaining) if remaining > 0
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
    def initialize(chunk_size = 8)
      if chunk_size == 1
        raise InvalidChunkSize.new(chunk_size)
      end

      super()
      @chunk_size = chunk_size
    end

    #######
    private
    #######

    # Internal: This is called with a +producer+, +point+, and +value+ each
    # time +calculate+ computes a value for a transient producer.
    #
    # Since +each_point+ skips +@chunk_size+ days at the end of each computed
    # day, this assigns the calculated value to that many days in order to
    # set a value for each point in the year.
    #
    # Returns nothing.
    def assign_load(producer, point, value)
      @chunk_size.times do |position|
        # Don't set values beyond Dec 24th @ 23:00.
        if (future_point = (position * PER_DAY) + point) < Merit::POINTS
          producer.set_load(future_point, value)
        end
      end
    end

    # Internal: Yields each point for which loads should be calcualted.
    #
    # This iterates through a day's worth of points, then skips forwards by
    # +@chunk_size+ days, before iterating through another day's worth. This
    # continues until we have reached the end of the year.
    #
    # Returns nothing.
    def each_point
      # The point being computed.
      point = 0

      # How many points in total are computed each time we compute a day.
      each_day = @chunk_size * PER_DAY

      # The number of points by which we increment when we have finished
      # computing a full day.
      day_incr = each_day - PER_DAY

      while point < Merit::POINTS
        yield point

        # Is this the end of the day (skip fowards), or are there still points
        # left to be calculated for the current day?
        point += (point % each_day == (PER_DAY - 1)) ? day_incr : 1
      end
    end
  end # QuantizingCalculator

  class AveragingCalculator < Calculator
    # Public: Creates a new AveragingCalculator which computes the production
    # load for each of the transient producers in a way which is faster than
    # the ordinary Calculator.
    #
    # The total amount of demand assigned is very accurate, however since
    # the averaging process "smooths out" demand/load during the +@chunk_size+
    # period the load is often assigned to transient producers differently
    # than the ordinary Calculator.
    #
    # On the upside, it is 5-6 times faster than Calculator.
    #
    # order      - The Merit::Order instance to be calculated.
    # chunk_size - How many days should be in each calculated "chunk". Lower
    #              numbers result in a more accurate calculation at the
    #              expense of performance.
    #
    # Returns an AveragingCalculator.
    def initialize(chunk_size = 8)
      if chunk_size == 1 || Merit::POINTS.remainder(chunk_size).nonzero?
        raise InvalidChunkSize.new(chunk_size)
      end

      super()
      @chunk_size = chunk_size
    end

    #######
    private
    #######

    # Internal: Yields each point for which loads should be calcualted.
    #
    # This combines +@chunk_size+ points together into a single iteration,
    # then jumps forwards by +@chunk_size+.
    #
    # Returns nothing.
    def each_point
      0.step(Merit::POINTS - 1, @chunk_size) { |point| yield point }
    end

    # Internal: Calcuates the total demand for the period following the given
    # +point+.
    #
    # order - The merit order.
    # point - The point in time.
    #
    # Returns a float.
    def demand(order, point)
      future = point + @chunk_size - 1

      order.participants.users.map do |user|
        user.load_between(point, future)
      end.reduce(:+)
    end

    # Internal: For a given +point+ in time, calculates the load which should
    # be handled by transient energy producers, and assigns the calculated
    # values to the producer's load curve.
    #
    # order     - The Merit::Order being calculated.
    # point     - The point in time, as an integer. Should be a value between
    #             zero and Merit::POINTS - 1.
    # producers - An object supplying the always_on and transient producers.
    #
    # Returns nothing.
    def compute_point(order, point, producers)
      remaining = demand(order, point)
      future    = point + @chunk_size - 1

      producers.always_on.each do |producer|
        remaining -= producer.load_between(point, future)
      end

      producers.transients.each do |producer|
        max_load = producer.load_between(point, future)

        # Optimisation: Load points default to zero, skipping to the next
        # iteration is faster then running the comparison / load_curve#set.
        next if max_load.zero?

        if max_load < remaining
          assign_load(producer, point, max_load)
        elsif remaining > 0.0
          assign_load(producer, point, remaining)
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
  end # AveragingCalculator
end # Merit
