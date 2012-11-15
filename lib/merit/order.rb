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

    # ---------- Calculate! -----------

    # Calculates the Merit Order and makes sure it happens only once
    #
    # Returns true when successful
    def calculate
      @calculate ||= recalculate!
    end

    # Recalculates
    # Returns true when we did them all
    def recalculate!
      Merit::POINTS.times do |point_in_time|
        export_production_loads_at(point_in_time)
      end
      true
    end

    # Returns the total demand for electricity at a certain time
    def demand_load_at(point_in_time)
      users.map{ |user| user.load_at(point_in_time) }.reduce(:+)
    end

    # Returns an Array containing the loads that are actually
    # produced according to the Merit Order.
    def production_loads_at(point_in_time)
      remaining_load = demand_load_at(point_in_time)
      production_loads = []
      max_production_loads_at(point_in_time).each do |max_load|
        if max_load < remaining_load
          production_loads << max_load
        else
          production_loads << [remaining_load, 0.0].max
        end
        remaining_load -= max_load
      end
      production_loads
    end

    # Records the production loads in the producer's load curve
    def export_production_loads_at(point_in_time)
      producers.zip(production_loads_at(point_in_time)).each do |producer,load|
        producer.load_curve.values[point_in_time] = load
      end
    end

    # Calculates the maximal production ALL the producers can take
    # Returns Float
    def max_production_load_at(point_in_time)
      max_production_loads_at(point_in_time).reduce(:+)
    end

    # Calculates the maximal production PER producer
    # Returns Array[Floats]
    def max_production_loads_at(point_in_time)
      producers.map{ |p| p.max_load_at(point_in_time) }
    end

    # Calculates the cumulative productions for the converters
    # TODO: remove, probably not needed
    def cumulative_max_production_loads_at(point_in_time)
      sum = 0
      max_production_loads_at(point_in_time).map do |load|
        sum += load
      end
    end

    # Public: returns an Array of all the producers, ordered
    # with the following in mind:
    #
    # - 1. volatiles (wind, solar, etc.)
    # - 2. must runs (chps, nuclear, etc.)
    # - 3. dispatchables (coal, gas, etc.)
    def producers
      volatiles + must_runs + dispatchables
    end

    # Public: Returns all the volatiles participants
    def volatiles
      participants.select{ |p| p.is_a?(VolatileProducer) }
    end

    # Public: Returns all the must_run participants
    def must_runs
      participants.select{ |p| p.is_a?(MustRunProducer) }
    end

    # Public: Returns all the dispatchables participants, ordered
    # by marginal_costs
    def dispatchables
      participants.select do
        |p| p.is_a?(DispatchableProducer)
      end.sort_by(&:marginal_costs)
    end

    # Public: returns all the users of electricity
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

    def summary
      rows = [['key',
               'class',
               'full load hours',
               'average load',
               'available output capacity',
      ]]
      producers.each do |p|
        rows << [p.key,
                 p.class,
                 p.full_load_hours,
                 p.average_load,
                 p.available_output_capacity
        ]
      end
      rows
    end

    def info
      puts Terminal::Table.new(
        :headings => summary[0],
        :rows     => summary[1..-1]
      )
    end

  end

end
