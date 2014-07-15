require 'spec_helper'

module Merit
  describe SupplyInterconnect do
    let(:price_curve) do
      Curve.new([
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
      ] * 365)
    end

    let(:ic) do
      SupplyInterconnect.new({
        key: :import_interconnect,
        price_curve: price_curve,
        availability: 1.0,
        fixed_costs_per_unit: 1.0,
        fix_om_costs_per_unit: 1.0,
        output_capacity_per_unit: 1.0,
        fixed_om_costs_per_unit: 1.0
      })
    end

    # --------------------------------------------------------------------------

    describe '#marginal_costs' do
      it 'raises an error' do
        expect { ic.marginal_costs }.to raise_error(VariableMarginalCost)
      end
    end

    describe '#marginal_cost_at' do
      it 'returns the cost for the given point' do
        expect(ic.marginal_cost_at(25)).to eq(2)
      end

      it 'returns 0.0 when given an invalid point' do
        expect(ic.marginal_cost_at(25000)).to be(0.0)
      end
    end # marginal_costs_at

    describe '#variable_costs' do
      let(:load_curve) do
        Curve.new([
          1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
          13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
        ] * 365)
      end

      before { ic.load_curve = load_curve }

      it 'returns the total variable cost for the year' do
        expect(ic.variable_costs).
          to eq(1.upto(24).map { |val| val * val }.reduce(:+) * 365)
      end
    end # variable_costs
  end # SupplyInterconnect
end # Merit
