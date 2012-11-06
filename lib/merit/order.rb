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

    # Public: adds a participant to this order
    # returns Participant
    def add_participant(*opts)
      participant = Participant.new({
        key:             opts[0],
        type:            opts[1],
        marginal_costs:  opts[2],
        capacity:        opts[3],
        availability:    opts[4],
        full_load_hours: opts[5]
      })
      @participants << participant
      participant
    end

    def to_s
      "<#{self.class}: #{@participants.size} participants>"
    end

  end

end
