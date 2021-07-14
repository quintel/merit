# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe SupplyInterconnect do
    let(:cost_curve) do
      Curve.new([
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
      ] * 365)
    end

    let(:ic) do
      described_class.new({
        key: :import_interconnect,
        cost_curve: cost_curve,
        availability: 1.0,
        fixed_costs_per_unit: 1.0,
        fix_om_costs_per_unit: 1.0,
        output_capacity_per_unit: 1.0,
        fixed_om_costs_per_unit: 1.0
      })
    end

    # --------------------------------------------------------------------------

    describe '#initialze' do
      it 'sets number of units to 1' do
        expect(ic.number_of_units).to eq(1)
      end
    end

    describe '#variable_costs' do
      let(:load_curve) do
        Curve.new([
          1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
          13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
        ] * 365)
      end

      before { ic.load_curve = load_curve }

      it 'returns the total variable cost for the year' do
        expect(ic.variable_costs)
          .to eq(1.upto(24).sum { |val| val * val } * 365)
      end
    end
  end
end
