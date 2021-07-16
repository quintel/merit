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
        # The producer has enough to meet demand, and then have some left over for flex
        # consumption.
        assign_excess(point, produced - demand, nil, flex) if produced.positive?
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
    # Returns nothing.
    def compute_price_sensitives(point, users, dispatchables, index)
      length = dispatchables.length

      return unless (length - index).positive? && users.any?

      # It's possible for the first dispatchable to have a current load exactly equal to the max
      # load. If this is the case we can skip it. This enables the `break if initial_load ==
      # producer_load` optimisation after the `users.each` loop (otherwise the loop may terminate
      # early).
      first_disp = dispatchables[index]
      index += 1 if first_disp.max_load_at(point) == first_disp.load_at(point)

      # This is an attempt to loop through the dispatchables array a second time, starting where
      # `compute_dispatchables` left off, without having to allocate another array or Enumerator.
      #
      # While `dispatchables[index..-1].each` would be more idiomatic, the while loop requires no
      # extra allocations.
      while index < length
        producer = dispatchables[index]

        unless producer.flex?
          assigned = assign_excess(
            point, producer.available_at(point), producer.cost_at(point), users
          )

          # If nothing as assigned, we can stop iterating as it means that the current price is too
          # high for any price-sensitive user. Subsequent dispatchables will be even more expensive.
          break if assigned.zero?

          producer.set_load(point, producer.load_at(point) + assigned)
        end

        index += 1
      end
    end

    # Internal: Assigns an amount of excess energy to the price-sensitive users.
    #
    # This splits the assignment into two phases, which broadly correspond with the outer and inner
    # loops:
    #
    #   1. Group users by their price, so that users with the same price will receive an equal share
    #      of energy.
    #
    #   2. Assign the available energy to users in each group.
    #
    # Once again, while loops are heavily used to avoid extra object allocations when iterating
    # through array slices.
    #
    # Returns a numeric: the amount of energy assigned.
    def assign_excess(point, available, price, users)
      index = 0
      initial_available = available

      while index < users.length
        break unless available.positive?
        break if price && users[index].cost_strategy.sortable_cost(point) <= price

        # Determine the index of the latest user with the same price as the current user. This
        # allows determining if energy should be assigned to one user, or shared equally between
        # several users.
        max_index = Flex::CostBasedShareGroup.max_index_with_same_price(users, point, index)

        if index == max_index
          # Only one user at the current price.
          available -= users[index].assign_excess(point, available)
          index += 1
        else
          # Multiple users with the same price. Assign energy equally.
          total_capacity = Flex::CostBasedShareGroup.total_unused_capacity(
            point, users, index, max_index
          )

          if total_capacity.positive?
            available -=
              Util.sum_slice(users, index, max_index) do |part|
                part.assign_excess(
                  point,
                  available * (part.unused_input_capacity_at(point) / total_capacity)
                )
              end
          end

          index = max_index + 1
        end
      end

      initial_available - available
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
