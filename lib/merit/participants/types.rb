module Merit

  class VolatileProducer < Producer
    def always_on?; true; end
  end

  class DispatchableProducer < Producer
    def always_on?; false; end
  end

  class MustRunProducer < Producer
    def always_on?; true; end
  end

end
