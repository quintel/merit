# frozen_string_literal: true

module Merit
  # Undertakes the arduous task of calculating the production load for the merit order.
  #
  #   Calculator.new.calculate(order)
  #
  # Terminology:
  #
  #   "always-on"  - Producers which must always be running, and therefore demand / load is assigned
  #                  to these first.
  #
  #   "transients" - The opposite of an always-on producer, these may be turned on and off as
  #                  necessary in order to fulfil any demand which cannot be provided by an
  #                  always-on producer.
  #
  class Calculator
    # Floating-point arithmetic errors are common during merit calculations and it is practically
    # impossible to check that a value is zero. Values less than this will be regarded as zero.
    APPROX_ZERO = 1e-11

    # Public: Performs the calculation. This sets the load curve values for each transient producer.
    #
    # order - The Merit::Order instance to be calculated.
    #
    # Returns self.
    def calculate(order)
      order.participants.lock!
      producers = order.participants.for_calculation

      each_point { |point| compute_point(order, point, producers) }

      self
    end

    private

    # Internal: Yields each point for which loads should be calcualted.
    #
    # This can be overridden in subclass if you want to calculate only a subset of the points.
    #
    # Returns nothing.
    def each_point(&block)
      Merit::POINTS.times(&block)
    end

    # Internal: Computes the total energy demand for a given +point+.
    #
    # order - The merit order.
    # point - The point in time.
    #
    # Returns a float.
    def demand_at(order, point)
      order.demand_calculator.demand_at(point)
    end

    # Internal: For a given +point+ in time, calculates the load which should be handled by
    # transient energy producers, and assigns the calculated values to the producer's load curve.
    #
    # This is the "jumping off point" for calculating the merit order, and note that the method is
    # called once per Merit::POINT. Since Calculator computes a value for every point (default 8,760
    # of them) even tiny changes can have large effects on the time taken to run the calculation.
    # Therefore, always benchmark / profile your changes!
    #
    # order        - The Merit::Order being calculated.
    # point        - The point in time, as an integer. Should be a value between zero and
    #                Merit::POINTS - 1.
    # participants - An object supplying the participants in the merit order.
    #
    # Returns nothing.
    def compute_point(order, point, participants)
      # Optimisation: This is order-dependent; it requires that always-on producers are before the
      # transient producers, otherwise "remaining" load will not be correct.
      #
      # Since this method is called a lot, being able to handle always-on and transient producers in
      # separate loops allows us to skip calling #always_on? in every iteration. This accounts for a
      # 20% reduction in the calculation runtime.

      if (demand = demand_at(order, point)).negative?
        raise SubZeroDemand.new(point, demand)
      end

      demand = compute_always_ons(
        point, demand,
        participants.always_on,
        participants.flex.at_point(point)
      )

      dispatchables = participants.dispatchables.at_point(point)
      next_idx = 0

      if demand.positive?
        next_idx = compute_dispatchables(point, dispatchables, demand)

        # There was unmet demand after running all dispatchables. It is not possible to satisfy any
        # price-sensitive demands (below).
        return if next_idx.nil?
      end

      compute_price_sensitives(
        point,
        participants.price_sensitive_users.at_point(point),
        dispatchables,
        next_idx
      )

      nil
    end

    # Internal: Computes always-on loads, assigning excess to flexibles.
    #
    # Returns the amount of demand which was not satisfied by energy produced by the always-on (the
    # deficit).
    def compute_always_ons(point, demand, always_ons, flex)
      produced = always_ons.sum { |producer| producer.max_load_at(point) }

      if produced > demand
        produced -= demand

        # The producer has enough to meet demand, and then have some left over for flex
        # consumption.
        flex.each { |part| produced -= part.assign_excess(point, produced) } if produced.positive?
        # assign_excess(point, produced, nil, flex)

        demand = 0.0
      elsif produced < demand
        # The producer is emitting less energy that demanded. Take it all and continue with the
        # next producer.
        demand -= produced
      end

      demand.negative? ? 0.0 : demand
    end

    # Internal: Computes the dispatchables load.
    #
    # Takes an enumerable of dispatchable producers and the remaining demand to be satisifed, and
    # sets the load on the producers needed to meet demand.
    #
    # Returns the amount of energy still to be satisfied after running dispatchables.
    #
    # Returns the `dispatchables` array, minus those producers which have no remaining capacity.
    # Note that the original `dispatchables` is modified in place for performance reasons.
    #
    # Returns the index of the first dispatchable which has capacity remaining, or nil if there is
    # no remaining capacity.
    def compute_dispatchables(point, dispatchables, remaining)
      # Hold and increment the index rather than using Enumerable#with_index, to avoid allocating an
      # Enumerator.
      index = -1

      dispatchables.each do |producer|
        index += 1
        max_load = producer.max_load_at(point)

        # Optimisation: Load points default to zero, skipping to the next iteration is faster then
        # running the comparison / load_curve#set.
        next if max_load.zero?

        if max_load < remaining
          producer.set_load(point, max_load)
          remaining -= max_load
        else
          producer.set_load(point, remaining) if remaining.positive?
          return index
        end
      end

      nil
    end

    # Internal: Computes demand for price-sensitive users.
    #
    # These users want energy, but only if the price of energy is less or equal to the price they
    # are willing to pay. These are run after calculating dispatchable loads.
    #
    # This method contains many instances of non-idiomatic Ruby due to slightly better performance
    # or fewer allocations; a single allocation in a loop can add up to tens of thousands of
    # allocations throughout the calculation. While loops are used for iteration, where a nice
    # helper method used to do the same job, as doing so avoids an object allocation when the helper
    # `yield`ed.
    #
    # Returns nothing.
    def compute_price_sensitives(point, users, dispatchables, disp_index)
      disp_length = dispatchables.length

      return unless (disp_length - disp_index).positive? && users.length.positive?

      users_index = 0

      while (user = users[users_index])
        users_index += 1

        available = available_for_ps_user(point, user, dispatchables, disp_index)

        # Price is now too high to assign any more energy.
        break if available.zero?

        disp_index = assign_ps_used_to_dispatchables(
          point,
          user.assign_excess(point, available),
          dispatchables,
          disp_index
        )
      end
    end

    # Internal: Given a point, a price-sensitive user, and the available dispatchables, returns how
    # much energy those dispatchables can provide the user at the price the user is willing to pay.
    #
    # A while loop is used as this is faster than an Enumerable-based helper, and avoids
    # allocations.
    #
    # point         - The point in the hour being calculated.
    # user          - The user that wishes energy.
    # dispatchables - The list of all dispatchables.
    # index         - The index of the first dispatchable which can provide energy.
    #
    # Returns a numeric.
    def available_for_ps_user(point, user, dispatchables, index)
      available = 0.0
      threshold = user.cost_strategy.cost_at(point)

      while (dispatchable = dispatchables[index])
        index += 1

        next 0.0 if dispatchable.flex?
        break if dispatchable.cost_strategy.cost_at(point) >= threshold

        available += dispatchable.available_at(point)
      end

      available
    end

    # Internal: Given an amount of energy which was assigned to a price-sensitive user, sets the
    # load on the dispatchables to reflect this energy use.
    #
    # Returns the index of the first dispatchable with remaining capacity (this index can be used
    # to more quickly calculate loads for other price-sensitive users).
    #
    # A while loop is used as this is faster than an Enumerable-based helper, and avoids
    # allocations.
    #
    # point         - The point in the hour being calculated.
    # assigned      - The amount of energy to be assigned.
    # dispatchables - The list of all dispatchables.
    # index         - The index of the first dispatchable which can provide energy.
    #
    # Returns a numeric.
    def assign_ps_used_to_dispatchables(point, assigned, dispatchables, disp_index)
      index = disp_index

      while (dispatchable = dispatchables[index])
        index += 1

        next if dispatchable.flex?

        available = dispatchable.available_at(point)

        if available > assigned
          # Producer could emit more than was used; these users are full.
          dispatchable.set_load(point, dispatchable.load_at(point) + assigned)
          assigned = 0

          # We've filled up all the users; any further dispatchables are unused.
          break
        else
          # Producer is at max capacity.
          dispatchable.set_load(point, dispatchable.load_at(point) + available)
          assigned -= available

          # This dispatchable is fully used. Further users should start with the next one.
          disp_index += 1
        end
      end

      disp_index
    end
  end

  # A calculator which behaves the same as the standard Calculator, but instead of calculating the
  # order immediately, returns a Proc which may be used to calculate each point in turn.
  #
  # For example
  #
  #   calculate_point = StepwiseCalculator.new.calculate
  #
  #   calculate_point.call(0) calculate_point.call(1)
  #   # ...
  #   calculate_point.call(8759)
  #
  class StepwiseCalculator < Calculator
    def calculate(order)
      order.participants.lock!

      participants = order.participants.for_calculation
      next_point = 0

      lambda do |point|
        raise InvalidCalculationOrder.new(point, next_point) if point != next_point
        raise OutOfBounds, point if point >= Merit::POINTS

        compute_point(order, point, participants)
        next_point += 1

        point
      end
    end
  end
end
