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

    describe '#price' do
      before do
        producer.load_curve.set(0, 0)
        producer.load_curve.set(1, 1)
      end

      it 'calculates the price to be equal to the marginal cost' do
        expect(strategy.price_at(0)).to eq(100.0)
      end

      it 'raises an error when the producer has non-zero load' do
        expect { strategy.price_at(1) }.
          to raise_error(Merit::InsufficentCapacityForPrice)
      end
    end # price
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

    describe 'with a cost of zero' do
      let(:attrs) { super().merge(marginal_costs: 0.0, cost_spread: 0.02) }

      it 'has a marginal cost of zero' do
        expect(strategy.marginal_cost).to be_zero
      end

      it 'has a sortable cost of zero' do
        expect(strategy.sortable_cost).to be_zero
      end

      it 'has a variable cost of zero' do
        expect(strategy.variable_cost).to be_zero
      end
    end # with a cost of zero

    describe '#price' do
      context 'when the producer does not provide a price' do
        it 'calculates the price for one additional plant' do
          expect(strategy.price_at(0)).to eq(99.6)
          expect(strategy.price_at(1)).to eq(100.8)
        end

        it 'raises an error when there is insufficient remaining capacity' do
          producer.load_curve.set(0, 91.0)

          expect { strategy.price_at(0) }.
            to raise_error(Merit::InsufficentCapacityForPrice)
        end
      end # when the producer does not provide a price

      context 'when the producer provides a price' do
        before do
          allow(producer).to receive(:provides_price?).and_return(true)
        end

        it 'calculates the price to be equal to the marginal cost' do
          expect(strategy.price_at(0)).to eq(99.4)
          expect(strategy.price_at(1)).to eq(100.6)
        end

        it 'raises no error when there is insufficient remaining capacity' do
          producer.load_curve.set(0, 100.0)
          expect(strategy.price_at(0)).to eq(101.0)
        end
      end # when the producer provides a price
    end # price
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

    describe '#price' do
      before do
        producer.load_curve.set(0, 0.0)
        producer.load_curve.set(2, 40.0)
      end

      it 'calculates the price to be equal to the marginal cost' do
        expect(strategy.price_at(0)).to eq(100.0)
      end

      it 'raises an error when the producer has non-zero load' do
        expect { strategy.price_at(2) }.
          to raise_error(Merit::InsufficentCapacityForPrice)
      end
    end # price
  end # LinearCostFunction
end ; end # describe CostStrategy ; Merit::CostStrategy
