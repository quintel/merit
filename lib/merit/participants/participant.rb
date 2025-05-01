# frozen_string_literal: true

module Merit
  # A participant is a plant or technology that participates in in the Merit Order, such as a coal
  # power plant, a wind turbine or a CHP.
  class Participant
    attr_reader   :key, :load_profile
    attr_accessor :order
    include Profitable

    # Public: creates a new participant
    #
    # params opts[Hash] set the attributes
    #
    # returns Participant
    def initialize(opts)
      @opts = opts
      require_attributes(:key)

      @key = opts[:key]
      @load_profile = opts[:load_profile]
    end

    def to_s
      "#<#{self.class} #{key}>"
    end

    alias_method :inspect, :to_s

    # Public: Does the producer have to be running (creating or consuming energy all of the time)?
    #
    # Returns true or false.
    def always_on?
      false
    end

    # Public: The inverse of #always_on?. Determines if this participant may sometimes be turned
    # off.
    def transient?
      !always_on?
    end

    # Public: Returns whether this participant is a user. Note that flexible technologies can
    # consume energy, but are not classed as users.
    def user?
      is_a?(Merit::User)
    end

    # Public: Returns whether this participant is a producer. Note that flexible technologies can
    # produce energy, but are not classed as producers.
    def producer?
      !user? && !flex?
    end

    # Public: Is this participant a flexible technology.
    #
    # Flexible technologies receive excess energy from always-on production.
    def flex?
      false
    end

    # Public: Returns the (actual) energy produced by this participant.
    def production(unit = :mj)
      case unit
      when :mj
        load_curve.sum * 3600
      when :mwh
        load_curve.sum
      else
        raise "Unknown unit: #{unit}"
      end
    end

    # Public: Used as the hash key when the participant is stored in a hash.
    #
    # This significantly improves the performance of `Sorting::Unsorted#initialize`, wherein each
    # participant is stored in a hash to ensure no duplicates.
    #
    # Returns an Integer.
    def hash
      self.class.name.hash ^ @key.hash
    end

    private

    def require_attributes(*attrs)
      attrs.each do |attr|
        raise MissingAttributeError.new(attr, self.class) unless @opts[attr]
      end
    end
  end
end
