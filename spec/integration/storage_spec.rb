# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Naming/VariableNumber
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe 'Calculation of storage' do
  context 'with two storage technologies' do
    let(:producer) do
      FactoryBot.build(:curve_producer, load_curve: Merit::Curve.new([20.0, 10.0] * 4380))
    end

    let(:user) do
      FactoryBot.build(:user_with_curve, load_curve: Merit::Curve.new([5.0, 18.0] * 4380))
    end

    let(:store_1) do
      FactoryBot.build(
        :storage,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 10.0,
        marginal_costs: storage_1_prices[:out],
        consumption_price: storage_1_prices[:in],
        volume_per_unit: 100.0
      )
    end

    let(:store_2) do
      FactoryBot.build(
        :storage,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 10.0,
        marginal_costs: storage_2_prices[:out],
        consumption_price: storage_2_prices[:in],
        volume_per_unit: 100.0
      )
    end

    before do
      order = Merit::Order.new

      order.add(producer)
      order.add(user)
      order.add(store_1)
      order.add(store_2)

      order.calculate
    end

    context 'when a participant has the same charge and discharge prices' do
      let(:storage_1_prices) { { in: 2.0, out: 2.0 } }
      let(:storage_2_prices) { { in: 1.0, out: 1.0 } }

      it 'assigns energy to the higher-priced store first' do
        expect(store_1.load_at(0)).to eq(-10)
      end

      it 'assigns remaining energy to the lower-priced store' do
        expect(store_2.load_at(0)).to eq(-5)
      end

      it 'discharges from the lower-priced store first' do
        expect(store_2.load_at(1)).to eq(5)
      end

      it 'discharges from the higher-priced store last' do
        expect(store_1.load_at(1)).to eq(3)
      end
    end

    context 'when a participant has different charge and discharge prices' do
      let(:storage_1_prices) { { in: 2.0, out: 1.0 } }
      let(:storage_2_prices) { { in: 1.0, out: 2.0 } }

      it 'assigns energy to the higher-priced store first' do
        expect(store_1.load_at(0)).to eq(-10)
      end

      it 'assigns remaining energy to the lower-priced store' do
        expect(store_2.load_at(0)).to eq(-5)
      end

      it 'discharges from the lower-priced store first' do
        expect(store_1.load_at(1)).to eq(8)
      end

      it 'discharges from the higher-priced store last' do
        expect(store_2.load_at(1)).to eq(0)
      end
    end
  end
end
# rubocop:enable Naming/VariableNumber
# rubocop:enable RSpec/MultipleMemoizedHelpers
