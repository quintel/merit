# The Load Profile contains the shape for the load of a technology/participant,
# or the total demand.
#
# Profiles are normalized such that multiplying them with the total produced
# electricity (in MJ) yields the load at every point in time in units of MW.

module Merit
  class LoadProfile

    attr_reader :key, :values

    require 'CSV'

    # Public: creates a new LoadProfile, and stores the accompanying values
    #         in an Array
    def initialize(key, values)
      @key    = key
      @values = scale_to_8760(values)
    end

    # Public: loads a stored LoadProfile for a given key
    # @param - key [Symbol]
    #
    # returns new LoadProfile
    def self.load(key)
      new(key, read_values_from_file(key))
    end

    def to_s
      "<#{self.class} #{values.size} values>"
    end

    # Public: checks wether the current Load Profile is valid: it should have a
    # length of 8.760, and the area below the curve should be equel to 1/3600
    #
    # Returns true or false
    def valid?
      values.size == 8760 && surface > 1/3601.0 && surface < 1/3599.0
    end

    # Public: returns the surface below the LoadProfile.
    def surface
      values.inject(:+)
    end

    def draw
      BarChart.new(@values).draw
    end

    #######
    private
    #######

    # Private: reads the values from a CSV file
    #
    # returns Array
    def self.read_values_from_file(key)
      path = "#{Merit.root}/load_profiles/#{key}.csv"

      begin
        values = CSV.read(path, converters: :numeric).flatten
      rescue Errno::ENOENT
        raise Merit::MissingLoadProfileError.new(key)
      end
    end

    # Private: translates an array which is a fraction of 8760 to one that
    # is 8760 long.
    #
    # returns Array
    def scale_to_8760(values)
      raise IncorrectLoadProfileError.new(key, values.size) unless 8760 % values.size == 0

      scaling_factor = 8760 / values.size
      values.map{|v| Array.new(scaling_factor, v)}.flatten
    end

  end
end
