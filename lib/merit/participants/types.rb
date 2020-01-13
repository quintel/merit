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

  class CurveProducer < Producer
    def initialize(opts)
      super
      require_attributes :load_curve

      @load_curve = opts[:load_curve]
    end

    def always_on?
      true
    end

    def max_load_at(point)
      @load_curve[point]
    end

    def max_load_curve
      @load_curve
    end
  end

  class DispatchableProducer < Producer
  end
end
