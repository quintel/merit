module Merit

  # The Order holds input and output together for the specific
  # required calculation.
  #
  # Example:
  #
  #   order = Order.new
  #
  #   order.add_participant(participant)
  #
  #   order.participants.first.full_load_hours
  #   => 1726.12
  #
  #   order.participant.first.profitablity
  #   => 102812122.90
  #
  class Order

    attr_reader   :participants
    attr_accessor :total_demand

    # Public: created a new Order
    def initialize(total_demand = nil)
      @participants = []
      @total_demand = total_demand
    end

    def load_curve
      @load_curve = LoadCurve.create(LoadProfile.load(:total_demand).values)
    end

    def must_runs
      @participants.select{ |p| p.is_a?(MustRunParticipant) }
    end

    def volatiles
      @participants.select{ |p| p.is_a?(VolatileParticipant) }
    end

    def dispatchables
      @participants.select{ |p| p.is_a?(DispatchableParticipant) }
    end

    # Public: adds a +dispatachble+ participant to this order
    # returns @participants
    def add_dispatchable(key, marginal_costs, capacity, availability)
      @participants  << DispatchableParticipant.new({
        key:             key,
        marginal_costs:  marginal_costs,
        capacity:        capacity,
        availability:    availability
      })
    end

    # Public: adds a +must_run+ participant to this order
    # returns @participants
    def add_must_run(key, load_profile, marginal_costs, capacity, availability, full_load_hours)
      @participants  << MustRunParticipant.new({
        key:             key,
        load_profile:    load_profile,
        marginal_costs:  marginal_costs,
        capacity:        capacity,
        availability:    availability,
        full_load_hours: full_load_hours
      })
    end

    # Public: adds a +must_run+ participant to this order
    # returns @participants
    def add_volatile(key, load_profile, marginal_costs, capacity, availability, full_load_hours)
      @participants  << VolatileParticipant.new({
        key:             key,
        load_profile:    load_profile,
        marginal_costs:  marginal_costs,
        capacity:        capacity,
        availability:    availability,
        full_load_hours: full_load_hours
      })
    end

    def to_s
      "<#{self.class}: #{@participants.size} participants, " \
      "demand: #{ total_demand ? total_demand : "not set" }>"
    end

  end

end
