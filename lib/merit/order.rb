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

    attr_accessor :total_demand

    # Public: created a new Order
    def initialize(total_demand = nil)
      @participants = {}
      @total_demand = total_demand
    end

    # -------- Participants ------------

    # Public: Returns all the must_run participants
    def must_runs
      participants.select{ |p| p.is_a?(MustRunParticipant) }
    end

    # Public: Returns all the volatiles participants
    def volatiles
      participants.select{ |p| p.is_a?(VolatileParticipant) }
    end

    # Public: Returns all the dispatchables participants
    def dispatchables
      participants.select{ |p| p.is_a?(DispatchableParticipant) }. \
        sort_by(&:marginal_costs)
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
      @participants[participant.key] = participant
    end

    def to_s
      "<#{self.class}: #{@participants.size} participants, " \
      "demand: #{ total_demand ? total_demand : "not set" }>"
    end

  end

end
