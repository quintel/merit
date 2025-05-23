# frozen_string_literal: true

module Merit
  # Helper module for classes which need to calculate the net load of a merit order.
  module NetLoadHelper
    def initialize(order, excludes = [])
      @order    = order
      @excludes = Set.new(excludes)
      Rails.logger.debug "[NetLoadHelper] init excludes=#{@excludes.to_a}"
    end

    def net_load
      p = production
      c = consumption
      net = p.each_with_index.map { |prod, i| (prod - c[i]).round(4) }
      Rails.logger.debug "[NetLoadHelper] net_load length=#{net.size} first5=#{net.first(5)} last5=#{net.last(5)}"
      net
    end

    def production
      parts = @order.participants.producers.reject { |part| @excludes.include?(part.key) }
      Rails.logger.debug "[NetLoadHelper] raw producer keys=#{@order.participants.producers.map(&:key)}"
      Rails.logger.debug "[NetLoadHelper] filtered producer keys=#{parts.map(&:key)} excludes=#{@excludes.to_a}"

      curves = parts.map(&:load_curve)
      Rails.logger.debug "[NetLoadHelper] individual production curve lengths=#{curves.map(&:size)}"

      total = CurveTools.add_curves(curves)
      Rails.logger.debug "[NetLoadHelper] combined production length=#{total.size} sample first5=#{total.first(5)}"
      total
    end

    def consumption
      curve = @order.demand_curve
      Rails.logger.debug "[NetLoadHelper] demand_curve length=#{curve.size} sample first5=#{curve.first(5)}"
      curve
    end
  end
end
