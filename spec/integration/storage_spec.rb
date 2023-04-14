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
        input_capacity_per_unit: 10.0, #why then load_curve MIN becomes -20? would make more sense for its MAX to be 20
        output_capacity_per_unit: 20.0,
        marginal_costs: storage_1_prices[:out],
        consumption_price: storage_1_prices[:in],
        decay: ->(*) { 0.0 },
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

      it 'never exceeds the output capcity of the first store' do
        expect(store_1.load_curve.values.max).to be <= store_1.output_capacity_per_unit
      end

      it 'never exceeds the output capcity of the second store' do
        expect(store_2.load_curve.values.max).to be <= store_2.output_capacity_per_unit
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

      it 'never exceeds the output capcity of the first store' do
        expect(store_1.load_curve.values.max).to be <= store_1.output_capacity_per_unit
      end

      it 'never exceeds the output capcity of the second store' do
        expect(store_2.load_curve.values.max).to be <= store_2.output_capacity_per_unit
      end
    end
  end

  context 'when there is export availability' do
    let(:export) do
      FactoryBot.build(
        :export,
        cost_curve: Merit::Curve.new([1.0, 0.0, 0.0, 0.9, 1.7] * 1752),
        input_capacity_per_unit: 30.0
      )
    end

    let(:producer) do
      FactoryBot.build(
        :curve_producer,
        load_curve: Merit::Curve.new([40.0, 10.0, 10.0, 0, 0] * 1752),
        marginal_costs: 0.0
      )
    end

    let(:store_1) do
      FactoryBot.build(
        :storage,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 20.0,
        marginal_costs: storage_1_prices[:out],
        consumption_price: storage_1_prices[:in],
        decay: ->(*) { 0.0 },
        volume_per_unit: 100.0
      )
    end

    let(:storage_1_prices) { { in: 1.0, out: 1.5 } }

    before do
      order = Merit::Order.new

      order.add(producer)
      order.add(export)
      order.add(store_1)

      order.calculate
    end

    it 'never exceeds the output capacity of the first store' do
      expect(store_1.load_curve.values.min).to be >= -store_1.input_capacity_per_unit
    end

    it 'never exceeds the input capacity of the first store' do
      expect(store_1.load_curve.values.max).to be <= store_1.output_capacity_per_unit
    end
  end
end
# rubocop:enable Naming/VariableNumber
# rubocop:enable RSpec/MultipleMemoizedHelpers
