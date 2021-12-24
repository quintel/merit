# frozen_string_literal: true

module Merit
  # Calculates the load of all participants in the merit order.
  #
  # Development note: A number of methods in this class use `while` loops rather than the more
  # idiomatic `Enumerable#each`. Doing so provides slightly better performance (up to 10ms in
  # demanding scenarios) and in some cases avoids allocating an object for each iteration.
  class Calculator
    # Floating-point arithmetic errors are common during merit calculations and it is practically
    # impossible to check that a value is zero. Values less than this will be regarded as zero.
    APPROX_ZERO = 1e-11

    # Public: Performs the calculation.
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

    # Internal: Computes the total energy demand for a given `point`.
    #
    # order - The merit order.
    # point - The point in time.
    #
    # Returns a float.
    def demand_at(order, point)
      order.demand_calculator.demand_at(point)
    end

    # Internal: For a given `point` in time, calculates the load of all the participants at that
    # point.
    #
    # This first determines the total amount of baseload demand; the energy demand which must be
    # satisfied at any cost. This is then followed by meeting that demand using always-on producers.
    # If demand is completely satisfied, excess energy from always-ons is then provided to flexible
    # technologies for storage or conversion to other energy carriers.
    #
    # If demand is not yet met, dispatchable energy producers are used in order of lowest to highest
    # cost until either demand is met or all dispatchables are fully loaded.
    #
    # Finally, when dispatchable capacity still remains, flexible technologies may be provided with
    # their energy when willing to pay more than the price of the dispatchable.
    #
    # Since Calculator computes a value for every point (defaults to 8,760), even tiny changes can
    # have large effects on the time taken to run the calculation. Always benchmark / profile your
    # changes!
    #
    # order        - The Merit::Order being calculated.
    # point        - The point in time, as an integer. Should be a value between zero and
    #                Merit::POINTS - 1.
    # participants - An object supplying the participants in the merit order.
    #
    # Returns nothing.
    def compute_point(order, point, participants)
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
        # There is enough production to meet demand and have some left over for flexibles.
        produced -= demand

        if produced.positive?
          flex.each do |part|
            produced -= part.barter_at(point, produced, 0)
            break if produced <= 0
          end
        end

        demand = 0.0
      elsif produced < demand
        demand -= produced
      end

      demand.negative? ? 0.0 : demand
    end

    # Internal: Computes the dispatchables load.
    #
    # Takes an enumerable of dispatchable producers and the remaining demand to be satisifed, and
    # sets the load on the producers needed to meet that demand.
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
    # are willing to pay.
    #
    # Returns nothing.
    def compute_price_sensitives(point, users, dispatchables, disp_index)
      disp_length = dispatchables.length

      # Exit immediately if no dispatchables are available, or there are no users.
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
    # point         - The point in the hour being calculated.
    # user          - The user that wishes energy.
    # dispatchables - The list of all dispatchables.
    # index         - The index of the first dispatchable which can provide energy.
    #
    # Returns a numeric.
    def available_for_ps_user(point, user, dispatchables, index)
      available = 0.0
      threshold = user.consumption_price.cost_at(point)

      while (dispatchable = dispatchables[index])
        index += 1

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

        available = dispatchable.available_at(point)

        if available > assigned
          # Producer could emit more than was used; these users are full.
          dispatchable.set_load(point, dispatchable.load_at(point) + assigned)
          assigned = 0

          # We've filled up all the users; any further dispatchables are unused.
          break
        elsif available.zero?
          # Check positive? because storage may return a negative load. We don't want to assign
          # anything in that case.
          disp_index += 1
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
