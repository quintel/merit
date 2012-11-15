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
      "<#{self.class}: #{values.size} values>"
    end

    # Public: creates a new drawing in the terminal for this LoadCurve
    def draw!
      BarChart.new(values).draw
    end

    def draw
      BarChart.new(values).drawing
    end

    # Public: substract one load curve from the other
    def -(other)
      self.class.new([values,other.values].transpose.map{ |x| x.reduce(:-) })
    end

    # Public: substract one load curve from the other
    def +(other)
      self.class.new([values,other.values].transpose.map{ |x| x.reduce(:+) })
    end

    # Public: returns the sample variance
    def variance
      mean = values.reduce(:+)/values.length.to_f
      sum = values.reduce(0) { |accum, i| accum +(i-mean)**2 }
      sum/(values.length - 1).to_f
    end

    # Public: returns the standard deviation
    def sd
      Math.sqrt(variance)
    end

    # Public: outputs the current load_curve to a csv file
    def to_csv(file_name = 'output.csv')
      CSV.open(File.join(Merit.root,'output',file_name), 'w') do |csv|
        values.each do |value|
          csv << [value]
        end
      end
    end

  end

end
