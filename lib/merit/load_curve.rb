module Merit

  # A LoadCurve is a container for LoadCurvevalues and is a timed
  # series
  #
  # It will contain the 'global' methods for e.g. the total_profit
  # of all the load_curve_values
  #
  class LoadCurve

    attr_accessor :values

    # Public: creates an empty LoadCurve
    def initialize(values)
      @values = values
    end

    def to_s
      "<#{self.class}: #{@values.size} values>"
    end

    def draw
      BarChart.new(@values).draw
    end

  end

end
