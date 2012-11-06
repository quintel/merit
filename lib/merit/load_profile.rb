# The Load Profile contains the shape for the load of a technology/participant,
# or the total demand.
# The area below the profile is always 1, and thus needs scaling

module Merit
  class LoadProfile

    attr_reader :values

    require 'CSV'

    # Public: creates a new LoadProfile, and stores the accompanying values
    def initialize(values)
      @values = values
    end

    # Public: loads a stored LoadProfile for a given key
    # @param key [String]
    # returns new LoadProfile
    def self.load(key)
      path = "#{Merit.root}/load_profiles/#{key}.csv"
      values = CSV.read(path, converters: :numeric).flatten

      self.new(values)
    end
  end
end
