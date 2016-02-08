require 'spec_helper'

module Merit
  describe Flex::BlackHole do
    let(:attrs) {{
      key: :bh,
      number_of_units: 1,
      output_capacity_per_unit: 10.0,
      input_efficiency: 1.0,
      output_efficiency: 1.0
    }}

    let(:bh) { Flex::BlackHole.new(attrs) }

    describe 'cost strategy' do
      it 'is Null' do
        expect(bh.cost_strategy).to be_a(CostStrategy::Null)
      end

      it 'is not price-setting' do
        expect(bh.cost_strategy.price_setting?(0)).to_not be
      end
    end # cost strategy

    describe 'max_load_at' do
      it 'returns zero' do
        expect(bh.max_load_at(0)).to be_zero
      end
    end # max_load_at

    describe 'storing 2.0' do
      let(:assign_load) { bh.assign_excess(1, 2.0) }

      context 'with a capacity of 10.0' do
        it 'returns 2.0' do
          expect(assign_load).to eq(2.0)
        end

        it 'sets a load of -2.0' do
          assign_load
          expect(bh.load_curve.get(1)).to eq(-2.0)
        end
      end # with a capacity of 10.0

      context 'with a capacity of 1.0' do
        let(:attrs) { super().merge(output_capacity_per_unit: 1.0) }

        it 'returns 1.0' do
          expect(assign_load).to eq(1.0)
        end

        it 'sets a load of -1.0' do
          assign_load
          expect(bh.load_curve.get(1)).to eq(-1.0)
        end
      end # with a capacity of 1.0

      context 'with a capacity of 3.0, 2.0 already stored' do
        before { bh.assign_excess(1, 2.0) }

        let(:attrs) { super().merge(output_capacity_per_unit: 3.0) }
        let(:assign_load) { bh.assign_excess(1, 2.0) }

        it 'returns 1.0' do
          expect(assign_load).to eq(1.0)
        end

        it 'sets a load of -3.0' do
          assign_load
          expect(bh.load_curve.get(1)).to eq(-3.0)
        end
      end # with a capacity of 10.0

      context 'with an input efficiency of 0.75' do
        let(:attrs) { super().merge(input_efficiency: 0.75) }

        it 'returns 2.0' do
          expect(assign_load).to eq(2.0)
        end

        it 'sets a load of -2.0' do
          assign_load
          expect(bh.load_curve.get(1)).to eq(-2.0)
        end

        context 'with a capacity of 3.0, 2.0 already stored' do
          before { bh.assign_excess(1, 2.0) }

          let(:attrs) { super().merge(output_capacity_per_unit: 3.0) }
          let(:assign_load) { bh.assign_excess(1, 2.0) }

          it 'returns 1.0' do
            expect(assign_load).to eq(1.0)
          end

          it 'sets a load of -3.0' do
            assign_load
            expect(bh.load_curve.get(1)).to eq(-3.0)
          end
        end # with a capacity of 10.0
      end # with an input efficiency of 0.75
    end # storing 2.0
  end # Flex::BlackHole
end
