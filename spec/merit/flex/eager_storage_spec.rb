# frozen_string_literal: true

require 'spec_helper'

describe Merit::Flex::EagerStorage do
  let(:attrs) do
    {
      key: :p2p,
      number_of_units: 1,
      input_capacity_per_unit: 6.0,
      output_capacity_per_unit: 8.0,
      input_efficiency: 1.0,
      output_efficiency: 1.0,
      volume_per_unit: 10.0
    }
  end

  let(:storage) { described_class.new(attrs) }

  # --

  context 'with volume=10, input_capacity=6, output_capacity=8' do
    context 'when empty' do
      it 'has a demand of 6' do
        expect(storage.load_at(0)).to eq(6)
      end

      it 'stores 6' do
        storage.load_at(0)
        expect(storage.reserve.at(0)).to eq(6)
      end

      it 'does not fill the store multiple times in the same frame' do
        storage.load_at(0)
        storage.load_at(0)

        expect(storage.load_at(0)).to eq(6)
      end

      it 'sets the load curve value' do
        storage.load_at(0)
        expect(storage.load_curve[0]).to eq(-6)
      end

      it 'has no production' do
        expect(storage.max_load_at(0)).to eq(0)
      end

      it 'does not assign any excess' do
        storage.assign_excess(0, 10.0)
        expect(storage.reserve.at(0)).to be_zero
      end

      it 'calculates production in Mwh' do
        storage.load_at(0)
        expect(storage.production(:mwh)).to eq(6)
      end

      it 'calculates production in MJ' do
        storage.load_at(0)
        expect(storage.production(:mj)).to eq(6 * 3600)
      end

      it 'cannot calculate production in other units' do
        storage.load_at(0)
        expect { storage.production(:no) }.to raise_error(/Unknown unit/)
      end
    end

    context 'when executing frame 1' do
      before do
        storage.load_at(0)
      end

      it 'has a demand of 4' do
        expect(storage.load_at(1)).to eq(4)
      end

      it 'has 10 stored' do
        storage.load_at(1)
        expect(storage.reserve.at(1)).to eq(10)
      end

      it 'does not fill the store multiple times in the same frame' do
        storage.load_at(1)
        storage.load_at(1)

        expect(storage.load_at(1)).to eq(4)
      end
    end

    context 'with 6 stored and subtracting 2 from frame 1' do
      before do
        storage.load_at(0)
        storage.load_at(1)
        storage.set_load(1, 2.0)
      end

      it 'has a demand of 2' do
        expect(storage.load_at(1)).to eq(2.0)
      end

      it 'sets the load curve value' do
        expect(storage.load_curve[1]).to eq(-2)
      end

      it 'has 8 stored' do
        expect(storage.reserve.at(1)).to eq(8)
      end
    end

    context 'with 10 stored' do
      before do
        storage.reserve.set(0, 10.0)
      end

      it 'has a potential production of 8' do
        expect(storage.max_load_at(0)).to eq(8)
      end
    end

    context 'with 10 stored and output_efficiency=0.5' do
      let(:attrs) { super().merge(output_efficiency: 0.5) }

      before { storage.reserve.set(0, 10.0) }

      it 'has a potential production of 5' do
        # output_capacity is 8, but reserve has 10. 10x0.5 = 5 which is less
        # than 8.
        expect(storage.max_load_at(0)).to eq(5)
      end

      it 'sets the load curve when taking 5' do
        storage.set_load(0, 5.0)
        expect(storage.load_curve[0]).to eq(5.0)
      end
    end

    context 'when executing frame 2' do
      before do
        storage.load_at(0)
        storage.load_at(1)
      end

      it 'has a demand of 0' do
        expect(storage.load_at(2)).to eq(0)
      end

      it 'has 10 stored' do
        storage.load_at(2)
        expect(storage.reserve.at(2)).to eq(10)
      end

      it 'does not fill the store multiple times in the same frame' do
        storage.load_at(2)
        storage.load_at(2)

        expect(storage.load_at(2)).to eq(0)
      end
    end

    context 'with input_efficiency=0.75' do
      let(:attrs) { super().merge(input_efficiency: 0.75) }

      it 'has a demand of 6' do
        expect(storage.load_at(0)).to eq(6)
      end

      it 'stores 4.5' do
        storage.load_at(0)
        expect(storage.reserve.at(0)).to eq(4.5)
      end

      it 'sets the load curve value' do
        storage.load_at(0)
        expect(storage.load_curve[0]).to eq(-6)
      end

      it 'has maximum production of 4.5' do
        storage.load_at(0)
        expect(storage.max_load_at(0)).to eq(4.5)
      end
    end

    context 'when 5 is stored' do
      before do
        storage.reserve.add(0, 5.0)
      end

      it 'has a demand of 5' do
        expect(storage.load_at(1)).to eq(5)
      end

      it 'has possible production of 5' do
        expect(storage.max_load_at(1)).to eq(5)
      end

      it 'sets the load curve value' do
        storage.load_at(1)
        expect(storage.load_curve[1]).to eq(-5)
      end
    end

    context 'when 5 is stored with output_efficiency=0.5' do
      before do
        storage.reserve.add(0, 5.0)
      end

      let(:attrs) { super().merge(output_efficiency: 0.5) }

      it 'has possible production of 2.5' do
        expect(storage.max_load_at(1)).to eq(2.5)
      end
    end
  end
end
