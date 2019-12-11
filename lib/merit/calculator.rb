# frozen_string_literal: true

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
    # Floating-point arithmetic errors are common during merit calculations and
    # it is practically impossible to check that a value is zero. Values less
    # than this will be regarded as zero.
    APPROX_ZERO = 1e-11

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

    private

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
      order.demand_calculator.demand_at(point)
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

      if (remaining = demand(order, point)).negative?
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

          if produced.positive?
            flex.each do |tech|
              produced -= tech.assign_excess(point, produced)

              # If there is no energy remaining to be assigned we can exit early
              # and, as an added bonus, prevent assigning tiny negatives
              # resulting from floating point errors, which messes up
              # technologies which have a Reserve with volume 0.0.
              break if produced <= APPROX_ZERO
            end
          end

          # Not all excess could be assigned; no point in trying to assign
          # energy from any more must runs.
          break if produced > APPROX_ZERO
        elsif produced < remaining
          # The producer is emitting less energy that demanded. Take it all and
          # continue with the next producer.
          remaining -= produced
        end

        remaining = 0.0 if remaining.negative?
      end

      return if remaining.zero?

      producers.transients(point).each do |producer|
        max_load = producer.max_load_at(point)

        # Optimisation: Load points default to zero, skipping to the next
        # iteration is faster then running the comparison / load_curve#set.
        next if max_load.zero?

        if max_load < remaining
          assign_load(producer, point, max_load)
        else
          assign_load(producer, point, remaining) if remaining.positive?
          break
        end

        # Subtract the production of the producer from the demand
        remaining -= max_load
      end
    end
  end

  # A calculator which behaves the same as the standard Calculator, but instead
  # of calculating the order immediately, returns a Proc which may be used to
  # calculate each point in turn.
  #
  # For example
  #
  #   calculate_point = StepwiseCalculator.new.calculate
  #
  #   calculate_point.call(0)
  #   calculate_point.call(1)
  #   # ...
  #   calculate_point.call(8759)
  #
  class StepwiseCalculator < Calculator
    def calculate(order)
      order.participants.lock!

      producers  = order.participants.producers_for_calculation
      next_point = 0

      lambda do |point|
        if point != next_point
          raise InvalidCalculationOrder.new(point, next_point)
        elsif point >= Merit::POINTS
          raise OutOfBounds, point
        end

        compute_point(order, point, producers)
        next_point += 1

        point
      end
    end
  end
end
