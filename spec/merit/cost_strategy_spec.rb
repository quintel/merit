require 'spec_helper'

module Merit::CostStrategy ; describe Merit::CostStrategy do
  let(:attrs) {{
    key:                      :fake,
    output_capacity_per_unit: 10.0,
    number_of_units:          10,
    availability:             1.0,
    fixed_costs_per_unit:     0.0,
    fixed_om_costs_per_unit:  0.0
  }}

  let(:load_curve) { Merit::Curve.new([20.0, 80.0] * 4380) }
  let(:producer)   { Merit::Producer.new(attrs) }
  let(:strategy)   { producer.cost_strategy }

  before { producer.load_curve = load_curve }

  describe Constant do
    let(:attrs) { super().merge(marginal_costs: 100.0) }

    it 'is a Constant' do
      expect(strategy).to be_a(Constant)
    end

    describe '#marginal_cost' do
      it 'calculates the marginal cost per MWh' do
        expect(strategy.marginal_cost).to eq(100.0)
      end
    end # marginal_cost

    describe '#sortable_cost' do
      it 'returns the marginal cost' do
        expect(strategy.sortable_cost).to eq(100.0)
      end
    end # #sortable_cost

    describe '#variable_cost' do
      it 'calculates the total annual variable cost' do
        expect(strategy.variable_cost).to eq(43800000.0)
      end
    end # variable_cost
  end # Constant

  describe LinearCostFunction do
    let(:attrs) { super().merge(marginal_costs: 100.0, cost_spread: 0.02) }

    it 'is a LinearCostFunction' do
      expect(strategy).to be_a(LinearCostFunction)
    end

    describe '#marginal_cost' do
      it 'calculates the marginal cost per MWh' do
        expect(strategy.marginal_cost).to eq(100.0)
      end
    end # marginal_cost

    describe '#sortable_cost' do
      # Give it an above-mean load.
      let(:load_curve) { Merit::Curve.new([50.0, 80.0] * 4380) }

      it 'returns the cost function using mean production' do
        expect(strategy.sortable_cost).to eq(100.0)
      end
    end # #sortable_cost

    describe '#variable_cost' do
      it 'calculates the total annual variable cost' do
        expect(strategy.variable_cost).to eq(43800000.0)
      end
    end # variable_cost
  end # LinearCostFunction

  describe FromCurve do
    let(:price) { Merit::Curve.new([250.0, 62.5] * 4380) }
    let(:attrs) { super().merge(cost_curve: price) }

    it 'is a FromCurve' do
      expect(strategy).to be_a(FromCurve)
    end

    describe '#marginal_cost' do
      it 'calculates the marginal cost per MWh' do
        expect(strategy.marginal_cost).to eq(100.0)
      end
    end # marginal_cost

    describe '#sortable_cost' do
      it 'returns the cost at the given point' do
        expect(strategy.sortable_cost(0)).to eq(250.0)
      end

      it 'returns the cost at a non-zero point' do
        expect(strategy.sortable_cost(1)).to eq(62.5)
      end
    end # #sortable_cost

    describe '#variable_cost' do
      it 'calculates the total annual variable cost' do
        expect(strategy.variable_cost).
          to be_within(1e4).of(43800000.0)
      end
    end # variable_cost
  end # LinearCostFunction
end ; end # describe CostStrategy ; Merit::CostStrategy
