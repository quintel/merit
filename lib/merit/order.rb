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

    attr_reader :price_setting_producers

    # Public: created a new Order
    def initialize(total_demand = nil)
      @participants            = {}
      @price_setting_producers = []
      if total_demand
        add(User.new(key: :total_demand))
        users.first.total_consumption = total_demand
      end
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
      memoize_participants!
      (calculator || self.class.calculator).calculate(self)
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

    # Public: Returns all the dispatchables participants, ordered
    # by marginal_costs
    def dispatchables
      @dispatchables ||
        select_participants(DispatchableProducer).sort_by(&:marginal_costs)
    end

    # Public: returns all the users of electricity
    def users
      @users || select_participants(User)
    end

    # Public Returns the participant for a given key, nil if not exists
    def participant(key)
      @participants[key]
    end

    # Public: Returns an array containing all the participants
    def participants
      @participants.values
    end

    # Public: Returns the price for a certain moment in time
    def price_at(time)
      producer = price_setting_producers[time] || dispatchables.last

      producer.marginal_costs
    end

    # Public: Returns a Curve with all the (known) prices
    # TODO: Rename LoadCurve to Curve
    def price_curve
      @price_curve ||= begin
        prices = LoadCurve.new
        POINTS.times { |point| prices.set(point, price_at(point)) }
        prices
      end
    end

    # Public: adds a participant to this order
    #
    # returns - participant
    def add(participant)
      raise LockedOrderError.new(participant) if @calculated

      participant.order = self

      # TODO: add DuplicateKeyError if collection already contains this key
      @participants[participant.key] = participant
    end

    def to_s
      "<#{self.class}" \
      " #{participants.size - users.size} producers," \
      " #{users.size} users >"
    end

    # Public: Returns an Array containing a 'table' with a row for every
    # producer and it's key, class, marginal costs,  full load hours.
    def summary
      rows = [['key',
               'class',
               'marginal costs',
               'full load hours',
               'production (PJ)'
      ]]
      producers.each do |p|
        rows << [p.key,
                 p.class,
                 p.marginal_costs,
                 p.full_load_hours,
                 p.production / 10**9
        ]
      end
      rows << ['TOTALS:',nil,nil,nil,producers.map(&:production).reduce(:+) / 10**9]
      rows
    end

    # Public: Returns an Array containing a 'table' with all the producers
    # vertically, and horizontally the power per point in time.
    def load_curves
      columns = []
      producers.each do |producer|
        columns << [producer.key,
                    producer.class,
                    producer.effective_output_capacity,
                    producer.number_of_units,
                    producer.load_curve.to_a
        ].flatten
      end
      columns.transpose
    end

    def info
      puts Terminal::Table.new(
        :headings => summary[0],
        :rows     => summary[1..-1]
      )
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
    def memoize_participants!
      @producers     = producers.freeze
      @volatiles     = volatiles.freeze
      @must_runs     = must_runs.freeze
      @dispatchables = dispatchables.freeze
      @users         = users.freeze
    end

    # Internal: Retrieves all member participants which are descendants of the
    # given +klass+.
    #
    # klass - The class of participants to be included.
    #
    # Returns an enumerable containing Participants.
    def select_participants(klass)
      participants.select { |participant| participant.is_a?(klass) }
    end

    # Internal: Yields each point for which loads should be calcualted.
    #
    # This can be overridden in subclass if you want to calculate only a
    # subset of the points.
    #
    # Returns nothing.
    def each_point
      Merit::POINTS.times { |point| yield point }
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
