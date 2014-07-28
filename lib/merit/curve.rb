module Merit
  # A Curve is a container for time series values, typically with one value for
  # each hour in the year. Values stored may include load on a producer, or
  # marginal costs which vary by hour.
  class Curve
    include Enumerable

    attr_reader :values

    # Public: Creates a Curve with the given +values+.
    #
    # values - The values for each point in the curve.
    # length - When the curve needs to be a specific length, but the supplied
    #          +values+ are shorter than this length, provide a +length+ to
    #          ensure that +each+ and +to_a+ always return the desired number of
    #          elements (empty elements will be returned as 0.0).
    #
    # Returns a Curve.
    def initialize(values = [], length = nil)
      @values = values
      @length = length
    end

    def get(point)
      @values[point] || 0.0
    end

    def set(point, value)
      @values[point] = value
    end

    def each
      length.times { |point| yield get(point) }
    end

    def length
      @length || @values.length
    end

    alias_method :size, :length

    def to_s
      "<#{self.class}: #{length} values>"
    end

    alias_method :inspect, :to_s

    # Public: creates a new drawing in the terminal for this Curve
    def draw
      BarChart.new(to_a).draw
    end

    # Public: substract one load curve from the other
    def -(other)
      self.class.new(transpose_other_curve(other.to_a, :-))
    end

    # Public: substract one load curve from the other
    def +(other)
      self.class.new(transpose_other_curve(other.to_a, :+))
    end

    # Public: multiplies one load curve with the other
    def *(other)
      self.class.new(transpose_other_curve(other.to_a, :*))
    end

    # Public: returns the sample variance
    def variance
      as_array = self.to_a

      mean = as_array.reduce(:+) / length.to_f
      sum  = as_array.reduce(0) { |accum, i| accum + (i - mean) ** 2 }

      sum / (length - 1).to_f
    end

    # Public: returns the standard deviation
    def sd
      Math.sqrt(variance)
    end

    # Public: Reads a file, and produces a Curve representing the content.
    #
    # The assumption is that the file contains the value of each point on a new
    # line.
    #
    # Returns a Curve.
    def self.load_file(path, length = nil)
      new(File.foreach(path).map(&:to_f), length)
    end

    #######
    private
    #######

    def transpose_other_curve(other, method)
      values = self.to_a

      v_length = values.length
      o_length = other.length

      if v_length > o_length
        other = other + ([0.0] * (v_length - o_length))
      elsif o_length > v_length
        values = values + ([0.0] * (o_length - v_length))
      end

      # Optimization: using each_with_index is 100ms faster for the complete
      # Merit::Order.
      new_values = []

      values.each_with_index do |value, index|
        new_values << value.send(method, other[index])
      end

      new_values
    end

  end # Curve
end # Merit
