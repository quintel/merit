module Merit
  module NetLoadHelper
    def initialize(order, excludes = [])
      @order    = order
      @excludes = excludes
    end

    def net_load
      production - consumption
    end

    def production
      @order.participants.producers
        .reject(&method(:excluded_from_participating))
        .map(&:load_curve)
        .reduce(:+)
    end

    def excluded_from_participating(producer)
      @excludes.include?(producer.key)
    end

    def consumption
      @order.participants.users.map(&:load_curve).reduce(:+)
    end
  end
end
