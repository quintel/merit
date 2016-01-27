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

    PROFIT_ATTRS = [ 'key',
                     'class',
                     'profitability',
                     'full_load_hours',
                     'profit',
                     'revenue',
                     'total_costs',
                     'fixed_costs',
                     'variable_costs',
                     'operating_costs' ]

    LOAD_ATTRS   = [ 'key',
                     'class',
                     'marginal_costs',
                     'full_load_hours',
                     'production' ]

    attr_reader :price_setting_producers

    # Public: created a new Order
    def initialize
      @price_setting_producers = Array.new(POINTS)
    end

    # ---------- Calculate! -----------

    # Calculates the Merit Order and makes sure it happens only once.
    # Optionally provide a Calculator instance if you want to use a faster, or
    # more accurate, algorithm.
    #
    # calculator - The calculator to use to compute the merit order. If the
    #              order has been calculated previously, this will be ignored.
    #
    # Returns self.
    def calculate(calculator = nil)
      @calculated ||= recalculate!(calculator)
      self
    end

    # Recalculates
    # Returns true when we did them all
    def recalculate!(calculator = nil)
      (calculator || self.class.calculator).calculate(self)
    end

    # Public: Returns an array containing all the participants
    def participants
      @participants ||= ParticipantSet.new
    end

    # Public: Returns the price for a certain moment in time. The price is
    # determined by the 'price setting producer', or it is just the most
    # expensive **installed** producer multiplied with a factor 7.22.
    # If there is no dispatchable available, we just take 600.
    #
    # See https://github.com/quintel/merit/issues/66#issuecomment-12317794
    # for the rationale of this factor 7.22
    def price_at(time)
      if producer = price_setting_producers[time]
        producer.price_at(time)
      elsif producer = participants.dispatchables.detect { |p| p.number_of_units > 0 && (! p.is_a?(Flex::Base)) && p.cost_strategy.price_setting?(time) }
        producer.price_at(time)
      elsif producer = participants.dispatchables.select { |p| p.number_of_units > 0 }.last
        producer.price_at(time, true) * 7.22
      else
        600
      end
    end

    # Public: Returns a Curve with all the (known) prices
    def price_curve
      @price_curve ||= begin
        prices = Curve.new
        POINTS.times { |point| prices.set(point, price_at(point)) }
        prices
      end
    end

    # Public: Returns a helper for calculating loss-of-load using the data given
    # to this Merit::Order.
    #
    # Returns a Merit::LOLE.
    def lole
      LOLE.new(self)
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
      "<##{ self.class } (#{ participants.to_s })>"
    end

    alias_method :inspect, :to_s

    def info
      puts CollectionTable.new(participants.producers, LOAD_ATTRS).draw!
    end

    def profit_info
      puts CollectionTable.new(participants.producers, PROFIT_ATTRS).draw!
    end

    # Public: Returns an Array containing a 'table' with all the producers
    # vertically, and horizontally the power per point in time.
    def load_curves
      columns = []
      participants.producers.each do |producer|
        columns << [producer.key,
                    producer.class,
                    producer.output_capacity_per_unit,
                    producer.number_of_units,
                    producer.load_curve.to_a
        ].flatten
      end
      columns.transpose
    end

    class << self
      # Public: Sets a calculator instance to use when calculating the loads
      # for merit orders when the user does not explicitly supply their own.
      #
      # calculator - A calculator to be used for computing merit orders.
      #
      # Returns the calculator.
      def calculator=(calculator)
        @calculator = calculator
      end

      # Internal: Returns the object to be used for calculating merit orders
      # when the user does not supply their own.
      #
      # Returns the calculator.
      def calculator
        @calculator ||= Calculator.new
      end
    end # class << self

  end # Order
end # Merit
