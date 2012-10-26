module Merit

  class LoadCurvePoint

    attr_accessor :load
    attr_reader   :cost, :price

    def initialize(load_value)
      @load = load_value
    end

    def running_plants
      Plant.all
    end

  end

end
