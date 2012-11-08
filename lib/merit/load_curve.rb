module Merit

  # A LoadCurve is a container for LoadCurvePoints and is a timed
  # series
  #
  # It will contain the 'global' methods for e.g. the total_profit
  # of all the load_curve_points
  #
  class LoadCurve

    attr_accessor :points

    # Public: creates an empty LoadCurve
    def initialize
      @points = []
    end

    def load
      points.map{|p|p.load}.inject(:+)
    end

    def to_s
      "<#{self.class}: #{@points.size} Points>"
    end

    # ----- Class Methods ------

    # Public: Creates a new LoadCurve from an array of load values for that
    # point
    #
    # params [Array] point_values
    #
    # Return a new LoadCurve
    def self.create(point_values)
      self.new.tap do |new|
        new.points = point_values.map{ |v| LoadCurvePoint.new(v) }
      end
    end

  end

end
