module Merit
  class VolatileProducer < Producer
    def initialize(opts)
      super
      require_attributes :full_load_hours, :load_profile
    end

    def always_on?
      true
    end
  end

  class MustRunProducer < Producer
    def initialize(opts)
      super
      require_attributes :full_load_hours, :load_profile
    end

    def always_on?
      true
    end
  end

  class DispatchableProducer < Producer
  end
end
