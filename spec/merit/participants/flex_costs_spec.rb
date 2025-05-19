# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe FlexCosts do
    let(:flex_base) do
      Flex::Base.new(
        key: :base,
        output_capacity_per_unit: 1.0,
        input_capacity_per_unit: 2.0,
        number_of_units: 1
      )
    end

    let(:order) { Order.new }

    before do
      # Flex::Base charges 2 for 50 hours and emits 1 for 100 hours
      50.times do |i|
        flex_base.assign_excess(i * 3, 2.0)
        flex_base.set_load((i * 3) + 1, 1.0)
        flex_base.set_load((i * 3) + 2, 1.0)
      end

      # Add participants to our fake order, and mock a price curve
      allow(order).to receive(:price_curve)
        .and_return(Curve.new(Array.new(8760, 0.05)))

      flex_base.order = order
    end

    describe '#revenue' do
      context 'when the flex_base has 0 units' do
        it 'returns zero' do
          allow(flex_base).to receive(:number_of_units).and_return(0)
          expect(flex_base.revenue).to be(0.0)
        end
      end

      context 'whith > 0 number of units' do
        it 'the flex_base returns the correct number' do
          expect(flex_base.revenue).to eq(100 * 0.05)
        end
      end
    end

    describe '#revenue_curve' do
      it 'returns a Curve' do
        expect(flex_base.revenue_curve).to be_a(Curve)
      end

      it 'the flex_base has a correct revenue for the first hour' do
        expect(flex_base.revenue_curve.to_a.first).to eq(0.0)
      end

      it 'the flex_base has a correct revenue for the second hour' do
        expect(flex_base.revenue_curve.to_a[1]).to eq(0.05)
      end
    end

    describe '#fuel_costs' do
      context 'when the flex_base has 0 units' do
        it 'returns zero' do
          allow(flex_base).to receive(:number_of_units).and_return(0)
          expect(flex_base.fuel_costs).to be(0.0)
        end
      end

      context 'whith > 0 number of units' do
        it 'the flex_base returns the correct number' do
          expect(flex_base.fuel_costs).to eq(50 * 2 * 0.05)
        end
      end
    end

    describe '#fuel_costs_curve' do
      it 'returns a Curve' do
        expect(flex_base.fuel_costs_curve).to be_a(Curve)
      end

      it 'the flex_base has a correct revenue for the first hour' do
        expect(flex_base.fuel_costs_curve.to_a.first).to eq(0.1)
      end

      it 'the flex_base has a correct revenue for the second hour' do
        expect(flex_base.fuel_costs_curve.to_a[1]).to eq(0.0)
      end
    end

    describe '#fuel_costs_per_mwh' do
      it 'the flex_base returns the correct number' do
        expect(flex_base.fuel_costs_per_mwh).to eq(0.05)
      end
    end
  end
end
