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
    def initialize(values = [], length = nil, default = 0.0)
      @values  = values
      @length  = length
      @default = default
    end

    def get(point)
      @values[point] || @default
    end

    alias [] get

    def set(point, value)
      @values[point] = value
    end

    alias []= set

    def each
      length.times { |point| yield get(point) }
    end

    def length
      @length || @values.length
    end

    alias_method :size, :length

    def to_s
      "#<#{ self.class }: #{ length } values>"
    end

    alias_method :inspect, :to_s

    # Public: creates a new drawing in the terminal for this Curve
    def draw
      BarChart.new(to_a).draw
    end

    # Public: substract one load curve from the other
    def -(other)
      self.class.new(transpose_other_curve(other, :-))
    end

    # Public: substract one load curve from the other
    def +(other)
      self.class.new(transpose_other_curve(other, :+))
    end

    # Public: multiplies one load curve with the other
    def *(other)
      self.class.new(transpose_other_curve(other, :*))
    end

    # Public: returns the sample variance
    def variance
      as_array = to_a

      mean = as_array.reduce(:+) / length.to_f
      sum  = as_array.reduce(0) { |accum, i| accum + (i - mean)**2 }

      sum / (length - 1).to_f
    end

    # Public: returns the standard deviation
    def sd
      Math.sqrt(variance)
    end

    # Internal: Sets which reader class to use for retrieving load profile
    # data from disk. Anything which responds to "read" and returns an array
    # of floats is acceptable.
    #
    # reader - The object to use to read the load profile data.
    #
    # Returns nothing.
    def self.reader=(klass)
      @reader = klass
    end

    # Internal: Returns the class to use for reading load profile data. If
    # none was set explicitly, the default Reader is used.
    #
    # Returns an object which responds to "read".
    def self.reader
      @reader ||= Reader.new
    end

    # Public: Reads a file, and produces a Curve representing the content.
    #
    # The assumption is that the file contains the value of each point on a new
    # line.
    #
    # Returns a Curve.
    def self.load_file(path)
      new(reader.read(path))
    end

    private

    def transpose_other_curve(other, method)
      if other.is_a?(Numeric)
        return @values.map { |value| value.public_send(method, other) }
      end

      values = to_a
      other  = other.to_a

      v_length = values.length
      o_length = other.length

      if v_length > o_length
        other += [@default] * (v_length - o_length)
      elsif o_length > v_length
        values += [@default] * (o_length - v_length)
      end

      # Optimization: using each_with_index is 100ms faster for the complete
      # Merit::Order.
      new_values = []

      values.each_with_index do |value, index|
        new_values << value.send(method, other[index])
      end

      new_values
    end

    # Internal: Loads curve information from a CSV file into an array of
    # numerics.
    class Reader
      def read(path)
        File.foreach(path).map(&:to_f)
      end
    end

    # Internal: A production-mode class for initializing curve data which caches
    # the information after it is loaded.
    class CachingReader < Reader
      def initialize
        @curves = {}
      end

      def read(path)
        key = path.to_s

        @curves[key] ||= super
        @curves[key].dup
      end
    end
  end
end
