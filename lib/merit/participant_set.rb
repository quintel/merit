# frozen_string_literal: true

module Merit
  # Stores Participants used in a Merit Order, and provides helpers for retrieving participants of a
  # given type, or meeting certain criteria.
  class ParticipantSet
    include Enumerable
    extend  Forwardable

    def_delegators :@members, :[], :length, :key?

    ForCalculation = Struct.new(:always_on, :dispatchables, :flex, :price_sensitive_users)

    # Creates a new ParticipantSet.
    def initialize
      @members = {}
      @locked = false
    end

    # Public: returns an +ordered+ Array of all the producers
    #
    # Ordering is as follows:
    #
    #   1. volatiles     (wind, solar, etc.)
    #   2. must runs     (chps, nuclear, etc.)
    #   3. dispatchables (coal, gas, etc.)
    def producers
      @producers || (volatiles + must_runs + dispatchables)
    end

    # Public: Returns all the volatiles participants
    def volatiles
      @volatiles || select_participants(VolatileProducer)
    end

    # Public: Returns all the must_run participants
    def must_runs
      @must_runs ||
        select_participants(MustRunProducer) +
          select_participants(CurveProducer)
    end

    # Public: Returns a ParticipantSet which can be used in a merit order calculation. In most
    # cases, this will return itself, however when one or more producers has a cost which varies
    # over time, a Resortable is returned instead.
    #
    # TODO: Update documentation.
    #
    # Returns something which responds to #always_on and #transients
    def for_calculation
      ForCalculation.new(
        always_on,
        Sorting.by_sortable_cost(dispatchables),
        Flex::Collection.new(Sorting.by_sortable_cost_desc(flex)),
        Flex::Collection.new(Sorting.by_sortable_cost_desc(price_sensitive_users))
      )
    end

    # Public: Returns all the dispatchables participants, ordered by marginal_costs. Sets the
    # dispatchable position attribute, which which starts with 1 and is set to -1 if the capacity
    # production is zero
    def dispatchables
      @dispatchables || begin
        dispatchables = select_participants(DispatchableProducer)
          .reject { |p| p.output_capacity_per_unit.zero? }

        # This ensures a stable sort: that if two participants have the same cost their original
        # order will be preserved.
        #
        # This should already be the case in Ruby, but there was a situation where two import
        # interconnectors had an identical cost and yet would be flipped after sorting. Attempts to
        # reproduce outside of Merit, and in tests, were unsuccessful. Yet, `dispatchables` above
        # would have the participants in the correct order, and after `sort_by!` the order would be
        # flipped.
        pos = 0

        dispatchables.sort_by! do |participant|
          [participant.cost_strategy.sortable_cost, pos += 1]
        end

        dispatchables
      end
    end

    # Public: Returns all participants which are flexible technologies.
    def flex
      @flex || select(&:flex?)
    end

    # Public: Returns all the users of energy except those which are price sensitive.
    def users
      @users || select_participants(User)
    end

    # Public: Returns users which are price sensitive.
    def price_sensitive_users
      @price_sensitive_users || begin
        ps_users =
          select_participants(User::PriceSensitive) +
          flex.flat_map { |f| Array(f) }.select(&:consume_from_dispatchables?)

        ps_users.uniq.sort_by { |u| -u.cost_strategy.sortable_cost }
      end
    end

    # Public: Returns all normal users, plus price-sensitive users.
    def all_users
      users + price_sensitive_users
    end

    # Public: Returns participants which may only be running sometimes.
    #
    # Accepts (and discards) an optional "point" parameter for API compatibility with Resortable.
    #
    # Returns an array of Producers.
    def transients(*)
      @transients || split_producers.last
    end

    # Public: Returns all participants which are always running.
    #
    # Accepts (and discards) an optional "point" parameter for API compatibility with Resortable.
    #
    # Returns an array of Producers.
    def always_on(*)
      @always_on || split_producers.first
    end

    # Public: Locks the ParticipantSet so that no more participants may be added. Memoizes the
    # various helper methods for fast lookups during merit order calculation.
    #
    # Returns true.
    def lock!
      @locked || begin
        memoize!
        @locked = true
        @members.freeze
        true
      end
    end

    # Public: Iterates through each participant in the order they were added.
    #
    # Returns nothing.
    def each
      @members.each { |_, participant| yield participant }
    end

    # Internal: Adds a `participant` to the set. For the moment, please use Order.add instead of
    # this method, as it will set the Participant#order.
    #
    # participant - The participant to be added to the set.
    #
    # Returns the participant, raising LockedOrderError if the merit order has been calculated
    # already, or DuplicateParticipant if the participant you are adding already exists.
    def add(participant)
      key = participant.key

      raise LockedOrderError, participant if @locked
      raise DuplicateParticipant, key if @members.key?(key) && @members[key] != participant

      @members[key] = participant
    end

    def to_s
      "#{producers.length} producers, #{users.length} users, " \
        "#{flex.length} flex, #{price_sensitive_users.length} price-sensitives"
    end

    def inspect
      "#<#{self.class.name} (#{self})>"
    end

    private

    # Internal: Stores each participant collection (must run, volatiles, etc) for faster retrieval.
    # This should only be done when all of the participants have been added, and you are ready to
    # perform the calculation.
    #
    # Returns nothing.
    def memoize!
      @volatiles     = volatiles.freeze
      @must_runs     = must_runs.freeze
      @dispatchables = dispatchables.freeze
      @producers     = producers.freeze
      @flex          = flex.freeze
      @users         = users.freeze
      @price_sensitive_users = price_sensitive_users.freeze

      @always_on, @transients = split_producers.map(&:freeze)
    end

    # Internal: Retrieves all member participants which are descendants of the given +klass+.
    #
    # klass - The class of participants to be included.
    #
    # Returns an enumerable containing Participants.
    def select_participants(klass)
      select { |participant| participant.is_a?(klass) }
    end

    # Internal: Splits participants into two groups; those which must run all the time, and those
    # which may be turned on and off as demand requires.
    #
    # Returns an array with always-on producers in the first element, and all other producers in the
    # second. Raises an IncorrectProducerOrder if an always-on producer appears after a transient
    # producer.
    def split_producers
      producers = self.producers

      # Not using Enumerable#partition allows us to quickly test that all the always-on producers
      # were before the first transient producer.
      partition = producers.index(&:transient?)

      return [producers.dup, []] if partition.nil?

      always_on = producers[0...partition]
      transient = producers[partition..-1] || []

      [always_on, transient]
    end
  end
end
