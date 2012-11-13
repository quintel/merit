module Merit

  # The Order holds input and output together for the specific
  # required calculation.
  #
  # Example:
  #
  #   order = Order.new
  #
  #   order.add(participant)
  #
  #   order.participants.first.full_load_hours
  #   => 1726.12
  #
  #   order.participant.first.profitablity
  #   => 102812122.90
  #
  class Order

    # Public: created a new Order
    def initialize(total_demand = nil)
      @participants = {}
      if total_demand
        add(User.new(key: :total_demand))
        users.first.total_consumption = total_demand
      end
    end

    # ---------- Load Queries ---------

    def residual_load
      users_load - must_runs_load - volatiles_load
    end

    def users_load
      users.map(&:load_curve).reduce(:+)
    end

    def must_runs_load
      must_runs.map(&:load_curve).reduce(:+)
    end

    def volatiles_load
      volatiles.map(&:load_curve).reduce(:+)
    end

    # -------- Queries --------------

    def dispatchable_capacity
      dispatchables.map(&:max_load).reduce(:+)
    end

    # Public: Returns all the must_run participants
    def must_runs
      participants.select{ |p| p.is_a?(MustRunProducer) }
    end

    # Public: Returns all the volatiles participants
    def volatiles
      participants.select{ |p| p.is_a?(VolatileProducer) }
    end

    # Public: Returns all the dispatchables participants
    def dispatchables
      participants.select do
        |p| p.is_a?(DispatchableProducer)
      end.sort_by(&:marginal_costs)
    end

    def users
      participants.select{ |p| p.is_a?(User) }
    end

    # Public Returns the participant for a given key, nil if not exists
    def participant(key)
      @participants[key]
    end

    # Public: Returns an array containing all the participants
    def participants
      @participants.values
    end

    # Public: adds a participant to this order
    #
    # returns - participant
    def add(participant)
      # TODO: add DuplicateKeyError if collection already contains this key
      @participants[participant.key] = participant
    end

    def to_s
      "<#{self.class}" \
      " #{participants.size - users.size} producers," \
      " #{users.size} users >"
    end

  end

end
