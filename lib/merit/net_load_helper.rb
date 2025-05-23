# frozen_string_literal: true

module Merit
  # Helper module for classes which need to calculate the net load of a merit order.
  module NetLoadHelper
    def initialize(order, excludes = [])
      @order    = order
      @excludes = Set.new(excludes)
    end

    def production
      parts = @order.participants.producers.reject { |part| @excludes.include?(part.key) }
      curves = parts.map(&:load_curve).map(&:to_a)

      # **log 389–391 for each non-zero producer**
      parts.zip(curves).each do |part, curve|
        slice = curve[389..391]
        next if slice.all?(&:zero?)
        Rails.logger.debug "[NetLoadHelper] producer #{part.key} @389–391 = #{slice.inspect}"
      end

      CurveTools.add_curves(curves)
    end

    def consumption
      curve = @order.demand_curve.to_a
      slice = curve[389..391]
      Rails.logger.debug "[NetLoadHelper] demand_curve @389–391 = #{slice.inspect}" unless slice.all?(&:zero?)
      @order.demand_curve
    end

    def net_load
      p = production.to_a
      c = consumption
      net = p.each_with_index.map { |prod, i| (prod - c[i]).round(4) }
      slice = net[389..391]
      Rails.logger.debug "[NetLoadHelper] net_load @389–391 = #{slice.inspect}" unless slice.all?(&:zero?)
      net
    end
  end
end
