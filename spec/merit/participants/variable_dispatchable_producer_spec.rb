# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::VariableDispatchableProducer do
  let(:availability) { [1.0, 1.0, 1.0, 1.0] }

  let(:producer) do
    avail = availability
    avail = (avail * (8760 / (avail.length - 1)))[0...8760] if avail.is_a?(Array)

    FactoryBot.build(
      :variable_dispatchable,
      output_capacity_per_unit: 100.0,
      availability: avail
    )
  end

  context 'with an availability curve' do
    let(:availability) { [0.0, 1.0, 0.5, -1.0, 2.0] }

    it 'has no capacity when availability is zero' do
      expect(producer.available_at(0)).to eq(0)
    end

    it 'has full capacity when availability is 1' do
      expect(producer.available_at(1)).to eq(100)
    end

    it 'has half capacity when availability is 0.5' do
      expect(producer.available_at(2)).to eq(50)
    end

    it 'has no capacity when availability is negative' do
      expect(producer.available_at(3)).to eq(0)
    end

    it 'has full capacity when availability is > 1' do
      expect(producer.available_at(4)).to eq(100)
    end

    it 'has a max load curve of [0, 100, 50, 0, 100]' do
      expect(producer.max_load_curve.take(5)).to eq([0, 100, 50, 0, 100])
    end
  end

  context 'with a constant availability curve of 1' do
    let(:availability) { [1.0] * 8760 }

    it 'has max production of 876,000' do
      expect(producer.max_production).to eq(876_000)
    end

    it 'has max load curve of [100, 100, ...]' do
      expect(producer.max_load_curve.to_a).to eq([100] * 8760)
    end

    it 'has raises an error when requesting available output_capacity' do
      expect { producer.available_output_capacity }.to raise_error(NotImplementedError)
    end

    context 'with 50% capacity used' do
      before do
        producer.set_load(0, 50)
      end

      it 'has 50% capacity available' do
        expect(producer.available_at(0)).to eq(50)
      end

      it 'has max production of 876,000' do
        expect(producer.max_production).to eq(876_000)
      end
    end
  end

  context 'with a constant availability curve of 0.5 and 50% capacity used' do
    let(:availability) { [0.5] * 8760 }

    it 'has max production of 438,000' do
      expect(producer.max_production).to eq(438_000)
    end

    it 'has max load curve of [50, 50, ...]' do
      expect(producer.max_load_curve.to_a).to eq([50] * 8760)
    end

    context 'with 50% capacity used' do
      before do
        producer.set_load(0, 50)
      end

      it 'has no capacity available' do
        expect(producer.available_at(0)).to eq(0)
      end

      it 'has max production of 438,000' do
        expect(producer.max_production).to eq(438_000)
      end
    end
  end

  context 'with a constant availability curve of 0.5 and 25% capacity used' do
    let(:availability) { [0.5] * 8760 }

    before do
      producer.set_load(0, 25)
    end

    it 'has 25% capacity available' do
      expect(producer.available_at(0)).to eq(25)
    end
  end

  context 'when initialized with a numeric availability' do
    let(:availability) { 0.5 }

    it 'raises an ArgumentError' do
      expect { producer }.to raise_error(ArgumentError, /must be an array of values/)
    end
  end
end
