module Merit
  # Stores Participants used in a Merit Order, and provides helpers for
  # retrieving participants of a given type, or meeting certain criteria.
  class ParticipantSet
    include Enumerable
    extend  Forwardable

    def_delegators :@members, :[], :length, :key?

    # Creates a new ParticipantSet.
    def initialize
      @members = {}
      @locked  = false
    end

    # Public: returns an +ordered+ Array of all the producers
    #
    # Ordering is as follows:
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
      @must_runs || select_participants(MustRunProducer)
    end

    # Public: Returns a ParticipantSet which can be used in a merit order
    # calculation. In most cases, this will return itself, however when one or
    # more producers has a cost which varies over time, a Resortable is returned
    # instead.
    #
    # Returns something which responds to #always_on and #transients
    def producers_for_calculation
      if producers.any? { |p| p.cost_strategy.variable? }
        ParticipantSet::Resortable.new(self)
      else
        self
      end
    end

    # Public: Returns all the dispatchables participants, ordered
    # by marginal_costs. Sets the dispatchable position attribute, which
    # which starts with 1 and is set to -1 if the capacity production is zero
    def dispatchables
      @dispatchables || begin
        position = 1

        dispatchables = select_participants(DispatchableProducer)

        unless dispatchables.any? { |p| p.cost_strategy.variable? }
          dispatchables.sort_by! { |p| p.cost_strategy.sortable_cost }

          dispatchables.each do |d|
            if d.output_capacity_per_unit * d.number_of_units == 0
              d.position = -1
            else
              d.position = position
              position += 1
            end
          end
        end

        dispatchables
      end
    end

    # Public: Returns all participants which are flexible technologies.
    #
    # TODO Sort by user-preference.
    def flex
      @flex || select_participants(Flex::Base)
    end

    # Public: Returns all the users of energy.
    def users
      @users || select_participants(User)
    end

    # Public: Returns participants which may only be running sometimes.
    #
    # Accepts (and discards) an optional "point" parameter for API compatibility
    # with Resortable.
    #
    # Returns an array of Producers.
    def transients(*)
      @transients || split_producers.last
    end

    # Public: Returns all participants which are always running.
    #
    # Accepts (and discards) an optional "point" parameter for API compatibility
    # with Resortable.
    #
    # Returns an array of Producers.
    def always_on(*)
      @always_on || split_producers.first
    end

    # Public: Locks the ParticipantSet so that no more participants may be
    # added. Memoizes the various helper methods for fast lookups during merit
    # order calculation.
    #
    # Returns true.
    def lock!
      @locked || (memoize! ; @locked = true ; @members.freeze ; true)
    end

    # Public: Iterates through each participant in the order they were added.
    #
    # Returns nothing.
    def each(&block)
      @members.each { |_, participant| block.call(participant) }
    end

    # Internal: Adds a `participant` to the set. For the moment, please use
    # Order.add instead of this method, as it will set the Participant#order.
    #
    # participant - The participant to be added to the set.
    #
    # Returns the participant, raising LockedOrderError if the merit order has
    # been calculated already, or DuplicateParticipant if the participant you
    # are adding already exists.
    def add(participant)
      key = participant.key

      if @locked
        fail LockedOrderError.new(participant)
      elsif @members.key?(key) && @members[key] != participant
        fail DuplicateParticipant.new(key)
      end

      @members[key] = participant
    end

    def to_s
      "#{ length - users.length } producers, #{ users.length } users"
    end

    def inspect
      "#<#{ self.class.name } (#{ to_s })>"
    end

    #######
    private
    #######

    # Internal: Stores each participant collection (must run, volatiles, etc)
    # for faster retrieval. This should only be done when all of the
    # participants have been added, and you are ready to perform the
    # calculation.
    #
    # Returns nothing.
    def memoize!
      @volatiles     = volatiles.freeze
      @must_runs     = must_runs.freeze
      @dispatchables = dispatchables.freeze
      @producers     = producers.freeze
      @flex          = flex.freeze
      @users         = users.freeze

      @always_on, @transients = split_producers.map(&:freeze)
    end

    # Internal: Retrieves all member participants which are descendants of the
    # given +klass+.
    #
    # klass - The class of participants to be included.
    #
    # Returns an enumerable containing Participants.
    def select_participants(klass)
      select { |participant| participant.is_a?(klass) }
    end

    # Internal: Splits participants into two groups; those which must run all
    # the time, and those which may be turned on and off as demand requires.
    #
    # Returns an array with always-on producers in the first element, and all
    # other producers in the second. Raises an IncorrectProducerOrder if an
    # always-on producer appears after a transient producer.
    def split_producers
      producers = self.producers

      # Not using Enumerable#partition allows us to quickly test that all the
      # always-on producers were before the first transient producer.
      partition = producers.index(&:transient?) || producers.length - 1

      always_on = producers[0...partition]
      transient = producers[partition..-1] || []

      if transient.any?(&:always_on?)
        raise Merit::IncorrectProducerOrder.new
      end

      return always_on, transient
    end

    # A class used in the merit order calculation when one or more producer has
    # a variable marginal cost, requiring the producers to be sorted in every
    # calculation point.
    class Resortable
      attr_reader :flex

      def initialize(set)
        @always_on, @transients, @flex =
          set.always_on, set.transients, set.flex
      end

      def always_on(point)
        @always_on.sort_by { |p| p.cost_strategy.sortable_cost(point) }
      end

      def transients(point)
        @transients.sort_by { |p| p.cost_strategy.sortable_cost(point) }
      end
    end
  end # ParticipantSet
end # Merit
