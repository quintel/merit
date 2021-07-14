# frozen_string_literal: true

module Merit
  # A producer whose output is fixed.
  class VolatileProducer < Producer
    def initialize(opts)
      super
      require_attributes(:full_load_hours, :load_profile)
    end

    def always_on?
      true
    end
  end

  # A producer whose output is fixed.
  class MustRunProducer < Producer
    def initialize(opts)
      super
      require_attributes(:full_load_hours, :load_profile)
    end

    def always_on?
      true
    end
  end

  # A producer whose output is set by a curve.
  class CurveProducer < Producer
    def initialize(opts)
      super
      require_attributes(:load_curve)

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

  # A producer whose load is conditional on there being demand. If there is no demand, a
  # dispatchable producer will be turned off.
  class DispatchableProducer < Producer
    def available_at(point)
      max_load_at(point) - @load_curve.get(point)
    end
  end
end
