# frozen_string_literal: true

module Merit
  # The Order holds input and output together for the specific required calculation.
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
    PROFIT_ATTRS = %w[
      key
      class
      profitability
      full_load_hours
      profit
      revenue
      total_costs
      fixed_costs
      variable_costs
      operating_costs
    ].freeze

    LOAD_ATTRS = %w[
      key
      class
      marginal_costs
      full_load_hours
      production
    ].freeze

    attr_accessor :fallback_price

    # Calculates the Merit Order and makes sure it happens only once.
    #
    # Optionally provide a Calculator instance if you want to use a faster, or more accurate,
    # algorithm.
    #
    # calculator - The calculator to use to compute the merit order. If the
    #              order has been calculated previously, this will be ignored.
    #
    # Returns self.
    def calculate(calculator = nil)
      @calculated ||= (calculator || self.class.calculator).calculate(self)
      self
    end

    # Public: Returns an array containing all the participants
    def participants
      @participants ||= ParticipantSet.new
    end

    # Public: Returns the sum of demand in each hour of the year.
    #
    # Calling this prior to calculating is liable to result in an incorrect curve if any of the
    # users contain a dynamic demand curve. No user in Merit provides this behaviour, but custom
    # users (such as in ETEngine) may.
    #
    # Returns a Merit::Curve.
    def demand_curve
      @demand_curve ||= CurveTools.add_curves(
        participants.users.reject(&:provides_price?).map(&:load_curve)
      )
    end

    def demand_calculator
      @demand_calculator ||= DemandCalculator.create(participants.users)
    end

    # Public: Returns a helper for calculating loss-of-load using the data given to this
    # Merit::Order.
    #
    # Returns a Merit::LOLE.
    def lole
      LOLE.new(self)
    end

    # Public: Returns a Curve with all the (known) prices
    def price_curve
      @price_curve ||= PriceCurve.new(self, fallback_price)
    end

    # Public: Returns a helper for calculating the excess of electricity for this Merit::Order
    #
    # Returns a Merit::Excess
    def excess(excludes = [])
      Excess.new(self, excludes)
    end

    # Public: Returns a helper for calculating the number of blackout hours for this Merit::Order
    #
    # Returns a Merit::Blackout
    def blackout
      Blackout.new(self)
    end

    # Public: adds a participant to this order
    #
    # returns - participant
    def add(participant)
      participants.add(participant)
      participant.order = self

      participant
    end

    def to_s
      "#<#{self.class} (#{participants})>"
    end

    alias_method :inspect, :to_s

    def info
      puts CollectionTable.new(participants.producers, LOAD_ATTRS).draw!
    end

    def profit_info
      puts CollectionTable.new(participants.producers, PROFIT_ATTRS).draw!
    end

    # Public: Returns an Array containing a 'table' with all the producers vertically, and
    # horizontally the power per point in time.
    def load_curves
      LoadCurvePresenter.present(self).transpose
    end

    class << self
      # Public: Sets a calculator instance to use when calculating the loads for merit orders when
      # the user does not explicitly supply their own.
      #
      # calculator - A calculator to be used for computing merit orders.
      #
      # Returns the calculator.
      attr_writer :calculator

      # Internal: Returns the object to be used for calculating merit orders when the user does not
      # supply their own.
      #
      # Returns the calculator.
      def calculator
        @calculator ||= Calculator.new
      end
    end
  end
end
