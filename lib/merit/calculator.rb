module Merit

  # The calculator holds input and output together for the specific
  # required calculation.
  #
  #   calculator = Calculator.new
  #
  #   calculator.add_participant(participant)
  #
  #   calculator.participants.first.full_load_hours
  #   => 1726.12
  #
  #   calculator.participant.first.profitablity
  #   => 102812122.90
  #
  class Calculator

    attr_accessor :participants, :load_curve

    def initialize(load_curve = nil)
      @participants = []
      @load_curve = load_curve
    end

    def add_participant(participant)
      @participants << participant
    end

    def to_s
      "<#{self.class}: #{@participants.size} participants, " \
      "#{@load_curve.points.size} Load curve points>"
    end

  end

end
