module Merit

  class LoadCurvePoint

    attr_accessor :load
    attr_reader   :cost, :price, :order

    def initialize(load_value)
      @load = load_value
    end

  end

end
