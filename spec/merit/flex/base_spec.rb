# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe Flex::Base do
    let(:attrs) do
      {
        key: :a,
        output_capacity_per_unit: 2.0,
        input_capacity_per_unit: 2.0,
        number_of_units: 1
      }
    end

    describe '#consumption_price' do
      context 'without a production_price attribute' do
        let(:flex) { described_class.new(attrs.merge(marginal_costs: 10.0)) }

        it 'defaults to the cost (production price) strategy' do
          expect(flex.consumption_price).to be(flex.cost_strategy)
        end

        it 'sets a Constant CostStrategy' do
          expect(flex.consumption_price).to be_a(Merit::CostStrategy::Constant)
        end

        it 'sets the sortable cost of the strategy' do
          expect(flex.consumption_price.sortable_cost(0)).to eq(10.0)
        end
      end

      context 'with a consumption_price attribute' do
        let(:flex) do
          described_class.new(attrs.merge(marginal_costs: 10.0, consumption_price: 20.0))
        end

        it 'does not default to the cost strategy' do
          expect(flex.consumption_price).not_to be(flex.cost_strategy)
        end

        it 'sets a Constant CostStrategy' do
          expect(flex.consumption_price).to be_a(Merit::CostStrategy::Constant)
        end

        it 'sets the sortable cost of the strategy' do
          expect(flex.consumption_price.sortable_cost(0)).to eq(20.0)
        end
      end
    end

    describe '#full_load_hours when number of units is zero' do
      let(:flex) do
        described_class.new(attrs.merge(input_capacity_per_unit: 1.0, number_of_units: 0.0))
      end

      it 'is zero' do
        expect(flex.full_load_hours).to eq(0)
      end
    end

    describe '#full_load_hours when input capacity is zero' do
      let(:flex) do
        described_class.new(attrs.merge(input_capacity_per_unit: 0.0, number_of_units: 1.0))
      end

      it 'is zero' do
        expect(flex.full_load_hours).to eq(0)
      end
    end

    describe '#full_load_hours when output capacity is 1 and input capacity is 2' do
      let(:attrs) do
        super().merge(output_capacity_per_unit: 1.0, number_of_units: 1.0)
      end

      let(:flex) do
        described_class.new(attrs)
      end

      context 'when receiving 2 for 50 hours' do
        before do
          50.times { |i| flex.assign_excess(i, 2.0) }
        end

        it 'is 50' do
          expect(flex.full_load_hours).to eq(50)
        end
      end

      context 'when receiving 1.5 for 75 hours' do
        before do
          75.times { |i| flex.assign_excess(i, 1.5) }
        end

        it 'is 56.25' do
          expect(flex.full_load_hours).to eq(56.25)
        end
      end

      context 'when receiving 2 for 50 hours and taking 1 for 100 hours' do
        before do
          50.times do |i|
            flex.assign_excess(i * 2, 2.0)
            flex.set_load(i * 2 + 1, 1.0)
          end
        end

        it 'is 50' do
          expect(flex.full_load_hours).to eq(50)
        end
      end
    end
  end
end
