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

    attr_reader   :participants
    attr_accessor :total_demand

    # Public: created a new Order
    def initialize(total_demand = nil)
      @participants = []
      @total_demand = total_demand
    end

    def load_curve
      raise UnknownDemandError unless total_demand
      @load_curve = LoadCurve.create(
        LoadProfile.load(:total_demand).values.map{ |v| v * total_demand }
      )
    end

    # Public: checks if a partipant is running
    def participants_running(partipant, point_in_time)
    end

    # -------- Participants ------------

    def must_runs
      @participants.select{ |p| p.is_a?(MustRunParticipant) }
    end

    def volatiles
      @participants.select{ |p| p.is_a?(VolatileParticipant) }
    end

    def dispatchables
      @participants.select{ |p| p.is_a?(DispatchableParticipant) }
    end

    # Public: adds a participant to this order
    #
    # returns - @participants
    def add(participant)
      @participants << participant
    end

    def to_s
      "<#{self.class}: #{@participants.size} participants, " \
      "demand: #{ total_demand ? total_demand : "not set" }>"
    end

  end

end
