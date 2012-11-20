# The Load Profile contains the shape for the load of a technology/participant,
# or the total demand.
#
# Profiles are normalized such that multiplying them with the total produced
# electricity (in MJ) yields the load at every point in time in units of MW.

module Merit
  class LoadProfile

    attr_reader :key, :values

    # Public: creates a new LoadProfile, and stores the accompanying values
    #         in an Array
    def initialize(key, values)
      @key    = key
      @values = scale_values(values)
    end


    def to_s
      "<#{self.class} #{values.size} values>"
    end

    # Public: checks wether the current Load Profile is valid: it should have a
    # length of 8.760, and the area below the curve should be equel to 1/3600
    #
    # Returns true or false
    def valid?
      values.size == Merit::POINTS && surface > 1/3601.0 && surface < 1/3599.0
    end

    # Public: returns the surface below the LoadProfile.
    def surface
      values.inject(:+)
    end

    def draw
      BarChart.new(@values).drawing
    end

    #######
    private
    #######

    # Internal: Translates an array whose length is a fraction of
    # Merit::POINTS to one that is precisely POINTS length. If the given
    # +values+ already have the correct length, no changes will be made.
    #
    # values - An array of values to be scaled.
    #
    # Returns an array of floats.
    def scale_values(values)
      return values if values.length == Merit::POINTS

      unless Merit::POINTS % values.length == 0
        raise IncorrectLoadProfileError.new(key, values.length)
      end

      factor = Merit::POINTS / values.length

      values.each_with_object([]) do |value, scaled|
        factor.times { scaled.push(value) }
      end
    end

    class << self
      # Internal: Sets which reader class to use for retrieving load profile
      # data from disk. Anything which responds to "read" and returns an array
      # of floats is acceptable.
      #
      # reader - The object to use to read the load profile data.
      #
      # Returns nothing.
      def reader=(klass)
        @reader = klass
      end

      # Internal: Returns the class to use for reading load profile data. If
      # none was set explicitly, the default Reader is used.
      #
      # Returns an object which responds to "read".
      def reader
        @reader ||= Reader.new
      end

      # Public: loads a stored LoadProfile for a given key
      # @param - key [Symbol]
      #
      # returns new LoadProfile
      def load(key)
        new(key, reader.read(key))
      end

      # Public: Returns Array with all the oad profiles stored
      def all
        Dir.glob("#{Merit.root}/load_profiles/*.csv").map do |path|
          key = File.basename(path, ".csv")
          self.load(key)
        end
      end
    end # class << self

    # Internal: Loads profile information from a "load_profiles" CSV file.
    class Reader
      def read(key)
        path   = "#{Merit.root}/load_profiles/#{key}.csv"
        values = []

        begin
          File.foreach(path) { |line| values.push(line.to_f) }
        rescue Errno::ENOENT
          raise Merit::MissingLoadProfileError.new(key)
        end

        values
      end
    end

    # Internal: A production-mode class for initializing load profile data
    # which caches the information after the first time it is retrieved.
    # Results in faster performance at the expensive of higher memory use.
    class CachingReader < Reader
      def initialize
        @profiles ||= Hash.new
      end

      def read(key)
        @profiles[key] ||= super
        @profiles[key].dup
      end
    end

  end
end
