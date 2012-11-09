module Merit

  class LoadCurvePoint

    attr_accessor :participants_running
    attr_reader   :cost, :price, :order, :load

    def initialize(load_value, order = nil)
      @load  = load_value
      @order = order
    end

    # Returns a hash containing the keys of the participants
    # and their load_fraction
    def current_participants
      {:coal => 1}
    end

    def calculate_with_participants()
      
    end

  end

end
