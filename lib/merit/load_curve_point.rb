module Merit

  class LoadCurvePoint

    attr_accessor :load
    attr_reader   :cost, :price, :order

    def initialize(load_value, order = nil)
      @load  = load_value
      @order = order
    end

  end

end
