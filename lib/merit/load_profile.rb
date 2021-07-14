# frozen_string_literal: true

module Merit
  # The Load Profile contains the shape for the load of a technology, participant or the total
  # demand.
  #
  # Profiles are normalized such that multiplying them with the total produced electricity (in MJ)
  # yields the load at every point in time in units of MW.
  class LoadProfile < Curve
    # Public: Creates a new LoadProfile, and stores the accompanying values in an Array.
    def initialize(values)
      super(scale_values(values))
    end

    # Public: checks wether the current Load Profile is valid: it should have a length of 8.760, and
    # the area below the curve should be equel to 1/3600
    #
    # Returns true or false
    def valid?
      values.size == Merit::POINTS &&
        surface > 1 / 3601.0 && surface < 1 / 3599.0
    end

    # Public: returns the surface below the LoadProfile.
    def surface
      values.sum
    end

    def draw
      BarChart.new(@values).drawing
    end

    private

    # Internal: Translates an array whose length is a fraction of Merit::POINTS to one that is
    # precisely POINTS length. If the given +values+ already have the correct length, no changes
    # will be made.
    #
    # values - An array of values to be scaled.
    #
    # Returns an array of floats.
    def scale_values(values)
      return values if values.length == Merit::POINTS

      raise IncorrectLoadProfileError, values.length unless (Merit::POINTS % values.length).zero?

      factor = Merit::POINTS / values.length

      values.each_with_object([]) do |value, scaled|
        factor.times { scaled.push(value) }
      end
    end

    class << self
      # Public: Loads a CSV file into a LoadProfile. See Curve#load_file.
      def load_file(path)
        super
      rescue IncorrectLoadProfileError => e
        raise "Invalid load profile at #{path}: #{e.message}"
      end

      alias_method :load, :load_file

      # See Curve.reader
      def reader
        Curve.reader
      end

      # See Curve.reader=
      def reader=(*)
        raise NotImplementedError, 'Set reader using Curve.reader='
      end
    end
  end
end
