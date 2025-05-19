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

    let(:storage) do
      Flex::Storage.new(
        key: :storage,
        number_of_units: 1,
        output_capacity_per_unit: 10.0,
        input_efficiency: 1.0,
        output_efficiency: 1.0,
        volume_per_unit: 10.0
      )
    end

    let(:storage_with_decay) do
      Flex::Storage.new(
        key: :storage,
        number_of_units: 1,
        output_capacity_per_unit: 10.0,
        input_efficiency: 1.0,
        output_efficiency: 1.0,
        volume_per_unit: 10.0,
        decay: ->(*) { 1.0 }
      )
    end

    # Optimising storage (standard load curve of only 10.0)
    let(:optimizing_storage_producer) do
      FactoryBot.build(:optimizing_storage_producer)
    end

    let(:optimizing_storage_consumer) do
      FactoryBot.build(:optimizing_storage_consumer)
    end

    # Missing optimizing storage:
    # Producer shoudl have it
    # How do we

    let(:order) { Order.new }
    let(:fluctuating_price_cuve) { Curve.new([0.05, 0.1, 0.05] * 2920) }

    # Charge 2 for 50 hours and emits 1 for 100 hours
    def mock_load_curve(participant)
      50.times do |i|
        participant.assign_excess(i * 3, 2.0)
        participant.set_load((i * 3) + 1, 1.0)
        participant.set_load((i * 3) + 2, 1.0)
      end
    end

    before do
      mock_load_curve(flex_base)
      mock_load_curve(storage)
      mock_load_curve(storage_with_decay)

      # Add participants to our fake order, and mock a price curve
      allow(order).to receive(:price_curve)
        .and_return(Curve.new(Array.new(8760, 0.05)))

      flex_base.order = order
      storage.order = order
      storage_with_decay.order = order
      optimizing_storage_producer.order = order
      optimizing_storage_consumer.order = order
    end

    describe '#revenue' do
      context 'when the flex_base has 0 units' do
        # Flex::Base
        it 'flex_base returns zero' do
          allow(flex_base).to receive(:number_of_units).and_return(0)
          expect(flex_base.revenue).to be(0.0)
        end

        # Flex::Storage
        it 'storage returns zero' do
          allow(storage).to receive(:number_of_units).and_return(0)
          expect(storage.revenue).to be(0.0)
        end

        # Flex::Storage with decay
        it 'storage with decay returns zero' do
          allow(storage_with_decay).to receive(:number_of_units).and_return(0)
          expect(storage_with_decay.revenue).to be(0.0)
        end

        # Optimising storage (producer)
        it 'optimising storage returns zero' do
          allow(optimizing_storage_producer).to receive(:number_of_units).and_return(0)
          expect(optimizing_storage_producer.revenue).to be(0.0)
        end
      end

      context 'with > 0 number of units' do
        # Flex::Base
        it 'the flex_base returns the correct number' do
          expect(flex_base.revenue).to eq(100 * 0.05)
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          expect(storage.revenue).to eq(100 * 0.05)
        end

        # Flex::Storage with decay
        it 'the storage with decay returns the correct number' do
          expect(storage_with_decay.revenue).to eq(100 * 0.05)
        end

        # Optimising storage (producer)
        it 'the optimising storage returns the correct number' do
          expect(optimizing_storage_producer.revenue).to eq(10.0 * 0.05 * 8760)
        end
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base returns the correct number' do
          expect(flex_base.revenue).to eq((50 * 0.05) + (50 * 0.1))
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          expect(storage.revenue).to eq((50 * 0.05) + (50 * 0.1))
        end

        # Flex::Storage with decay
        it 'the storage with decay returns the correct number' do
          expect(storage_with_decay.revenue).to eq((50 * 0.05) + (50 * 0.1))
        end

        # Optimising storage (producer)
        it 'the optimised storage returns the correct number' do
          expect(optimizing_storage_producer.revenue).to eq((5840 * 10.0 * 0.05) + (2920 * 10.0 * 0.1))
        end
      end
    end

    describe '#revenue_curve' do
      it 'returns a Curve' do
        expect(flex_base.revenue_curve).to be_a(Curve)
      end

      # Flex::Base
      it 'the flex_base has a correct revenue for the first hour' do
        expect(flex_base.revenue_curve.to_a.first).to eq(0.0)
      end

      it 'the flex_base has a correct revenue for the second hour' do
        expect(flex_base.revenue_curve.to_a[1]).to eq(0.05)
      end

      # Flex::Storage
      it 'the storage has a correct revenue for the first hour' do
        expect(storage.revenue_curve.to_a.first).to eq(0.0)
      end

      it 'the storage has a correct revenue for the second hour' do
        expect(storage.revenue_curve.to_a[1]).to eq(0.05)
      end

      # Flex::Storage with decay
      it 'the storage_with_decay has a correct revenue for the first hour' do
        expect(storage_with_decay.revenue_curve.to_a.first).to eq(0.0)
      end

      it 'the storage_with_decay has a correct revenue for the second hour' do
        expect(storage_with_decay.revenue_curve.to_a[1]).to eq(0.05)
      end

      # Optimising storage (producer)
      it 'the optimised storage has a correct revenue for the first hour' do
        expect(optimizing_storage_producer.revenue_curve.to_a.first).to eq(0.5)
      end

      it 'the optimised storage has a correct revenue for the second hour' do
        expect(optimizing_storage_producer.revenue_curve.to_a[1]).to eq(0.5)
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base has a correct revenue for the first hour' do
          expect(flex_base.revenue_curve.to_a.first).to eq(0.0)
        end

        it 'the flex_base has a correct revenue for the second hour' do
          expect(flex_base.revenue_curve.to_a[1]).to eq(0.1)
        end

        # Flex::Storage
        it 'the storage has a correct revenue for the first hour' do
          expect(storage.revenue_curve.to_a.first).to eq(0.0)
        end

        it 'the storage has a correct revenue for the second hour' do
          expect(storage.revenue_curve.to_a[1]).to eq(0.1)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay has a correct revenue for the first hour' do
          expect(storage_with_decay.revenue_curve.to_a.first).to eq(0.0)
        end

        it 'the storage_with_decay has a correct revenue for the second hour' do
          expect(storage_with_decay.revenue_curve.to_a[1]).to eq(0.1)
        end

        # Optimising storage (producer)
        it 'the optimised storage has a correct revenue for the first hour' do
          expect(optimizing_storage_producer.revenue_curve.to_a.first).to eq(0.5)
        end

        it 'the optimised storage has a correct revenue for the second hour' do
          expect(optimizing_storage_producer.revenue_curve.to_a[1]).to eq(1.0)
        end
      end
    end

    describe '#fuel_costs' do
      context 'when the flex_base has 0 units' do
        it 'returns zero' do
          allow(flex_base).to receive(:number_of_units).and_return(0)
          expect(flex_base.fuel_costs).to be(0.0)
        end
      end

      context 'with > 0 number of units' do
        # Flex::Base
        it 'the flex_base returns the correct number' do
          expect(flex_base.fuel_costs).to eq(50 * 2 * 0.05)
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          expect(storage.fuel_costs).to eq(50 * 2 * 0.05)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay returns the correct number' do
          expect(storage_with_decay.fuel_costs).to eq(50 * 2 * 0.05)
        end

        # Optimising storage (consumer)
        it 'the optimised storage returns the correct number' do
          expect(optimizing_storage_consumer.fuel_costs).to eq(10.0 * 0.05 * 8760)
        end
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base returns the correct number' do
          expect(flex_base.fuel_costs).to eq(100 * 0.05)
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          expect(storage.fuel_costs).to eq(100 * 0.05)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay returns the correct number' do
          expect(storage_with_decay.fuel_costs).to eq(100 * 0.05)
        end

        # Optimising storage (consumer)
        it 'the optimised storage returns the correct number' do
          expect(optimizing_storage_consumer.fuel_costs).to eq((5840 * 10.0 * 0.05) + (2920 * 10.0 * 0.1))
        end
      end
    end

    describe '#fuel_costs_curve' do
      it 'returns a Curve' do
        expect(flex_base.fuel_costs_curve).to be_a(Curve)
      end

      # Flex::Base
      it 'the flex_base has a correct fuel cost for the first hour' do
        expect(flex_base.fuel_costs_curve.to_a.first).to eq(0.1)
      end

      it 'the flex_base has a correct fuel cost for the second hour' do
        expect(flex_base.fuel_costs_curve.to_a[1]).to eq(0.0)
      end

      # Flex::Storage
      it 'the storage has a correct fuel cost for the first hour' do
        expect(storage.fuel_costs_curve.to_a.first).to eq(0.1)
      end

      it 'the storage has a correct fuel cost for the second hour' do
        expect(storage.fuel_costs_curve.to_a[1]).to eq(0.0)
      end

      # Flex::Storage with decay
      it 'the storage_with_decay has a correct fuel cost for the first hour' do
        expect(storage_with_decay.fuel_costs_curve.to_a.first).to eq(0.1)
      end

      it 'the storage_with_decay has a correct fuel cost for the second hour' do
        expect(storage_with_decay.fuel_costs_curve.to_a[1]).to eq(0.0)
      end

      # Optimising storage (consumer)
      it 'the optimised storage has a correct fuel cost for the first hour' do
        expect(optimizing_storage_consumer.fuel_costs_curve.to_a.first).to eq(10.0 * 0.05)
      end

      it 'the optimised storage has a correct fuel cost for the second hour' do
        expect(optimizing_storage_consumer.fuel_costs_curve.to_a[1]).to eq(10.0 * 0.05)
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base has a correct fuel cost for the first hour' do
          expect(flex_base.fuel_costs_curve.to_a.first).to eq(0.1)
        end

        it 'the flex_base has a correct fuel cost for the second hour' do
          expect(flex_base.fuel_costs_curve.to_a[1]).to eq(0.0)
        end

        # Flex::Storage
        it 'the storage has a correct fuel cost for the first hour' do
          expect(storage.fuel_costs_curve.to_a.first).to eq(0.1)
        end

        it 'the storage has a correct fuel cost for the second hour' do
          expect(storage.fuel_costs_curve.to_a[1]).to eq(0.0)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay has a correct fuel cost for the first hour' do
          expect(storage_with_decay.fuel_costs_curve.to_a.first).to eq(0.1)
        end

        it 'the storage_with_decay has a correct fuel cost for the second hour' do
          expect(storage_with_decay.fuel_costs_curve.to_a[1]).to eq(0.0)
        end

        # Optimising storage (consumer)
        it 'the optimised storage has a correct fuel cost for the first hour' do
          expect(optimizing_storage_consumer.fuel_costs_curve.to_a.first).to eq(10.0 * 0.05)
        end

        it 'the optimised storage has a correct fuel cost for the second hour' do
          expect(optimizing_storage_consumer.fuel_costs_curve.to_a[1]).to eq(10.0 * 0.1)
        end
      end
    end

    describe '#fuel_costs_per_mwh' do
      # Flex::Base
      it 'the flex_base returns the correct number' do
        expect(flex_base.fuel_costs_per_mwh).to eq(0.05)
      end

      # Flex::Storage
      it 'the storage returns the correct number' do
        expect(storage.fuel_costs_per_mwh).to eq(0.05)
      end

      # Flex::Storage with decay
      it 'the storage_with_decay returns the correct number' do
        expect(storage_with_decay.fuel_costs_per_mwh).to eq(0.05)
      end

      # Optimising storage (consumer)
      it 'the optimised storage returns the correct number' do
        expect(optimizing_storage_consumer.fuel_costs_per_mwh).to eq(0.05)
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base returns the correct number' do
          expect(flex_base.fuel_costs_per_mwh).to eq(0.05)
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          expect(storage.fuel_costs_per_mwh).to eq(0.05)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay returns the correct number' do
          expect(storage_with_decay.fuel_costs_per_mwh).to eq(0.05)
        end

        # Optimising storage (consumer)
        it 'the optimised storage returns the correct number' do
          expect(optimizing_storage_consumer.fuel_costs_per_mwh).to eq((0.1 + 0.05 + 0.05) / 3)
        end
      end
    end

    describe '#revenue_per_mwh' do
      # Flex::Base
      it 'the flex_base returns the correct number' do
        expect(flex_base.revenue_per_mwh).to eq(0.05)
      end

      # Flex::Storage
      it 'the storage returns the correct number' do
        expect(storage.revenue_per_mwh).to eq(0.05)
      end

      # Flex::Storage with decay
      it 'the storage_with_decay returns the correct number' do
        expect(storage_with_decay.revenue_per_mwh).to eq(0.05)
      end

      # Optimising storage (producer)
      it 'the optimised storage returns the correct number' do
        expect(optimizing_storage_producer.revenue_per_mwh).to eq(0.05)
      end

      context 'when the price curve fluctuates' do
        before do
          allow(order).to receive(:price_curve)
            .and_return(fluctuating_price_cuve)
        end

        # Flex::Base
        it 'the flex_base returns the correct number' do
          # ((50 * 0.05) + (50 * 0.1)) / 100 = 0.075
          expect(flex_base.revenue_per_mwh).to eq(0.075)
        end

        # Flex::Storage
        it 'the storage returns the correct number' do
          # ((50 * 0.05) + (50 * 0.1)) / 100 = 0.075
          expect(storage.revenue_per_mwh).to eq(0.075)
        end

        # Flex::Storage with decay
        it 'the storage_with_decay returns the correct number' do
          # ((50 * 0.05) + (50 * 0.1)) / 100 = 0.075
          expect(storage_with_decay.revenue_per_mwh).to eq(0.075)
        end

        # Optimising storage (producer)
        it 'the optimised storage returns the correct number' do
          expect(optimizing_storage_producer.revenue_per_mwh).to eq((0.1 + 0.05 + 0.05) / 3)
        end
      end
    end
  end
end
