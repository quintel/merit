# frozen_string_literal: true

module Merit
  # Helper module for classes which need to calculate the net load of a merit order.
  class NetLoad
    include NetLoadHelper

    def net_load
      @net_load ||= super
    end

    def production
      @production ||= super
    end
  end
end
