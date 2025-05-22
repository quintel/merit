# frozen_string_literal: true

require 'spec_helper'

module Merit
  RSpec.describe Blackout do
    let(:blackout) { described_class.new(net_load) }
    let(:eps) { described_class::EPSILON }

    context 'when the net load is constant 0' do
      let(:net_load)  { [0.0] * 8760 }

      it 'has no blackout hours' do
        expect(blackout.number_of_hours).to eq(0)
      end

      it 'has zero blackout volume' do
        expect(blackout.volume).to eq(0)
      end

      it 'has zero blackout peak' do
        expect(blackout.peak).to eq(0.0)
      end
    end

    context 'when the net load is constant 1' do
      let(:net_load)  { [1.0] * 8760 }

      it 'has no blackout hours' do
        expect(blackout.number_of_hours).to eq(0)
      end

      it 'has zero blackout volume' do
        expect(blackout.volume).to eq(0)
      end

      it 'has zero blackout peak' do
        expect(blackout.peak).to eq(0.0)
      end
    end

    context 'when the net load is constant -1' do
      let(:net_load)  { [-1.0] * 8760 }

      it 'has 8760 blackout hours' do
        expect(blackout.number_of_hours).to eq(8760)
      end

      it 'has correct blackout volume' do
        expect(blackout.volume).to eq(8760.0)
      end

      it 'has correct blackout peak' do
        expect(blackout.peak).to eq(1.0)
      end
    end

    context 'when the net load alternates between -1 and 1' do
      let(:net_load)  { [-1.0, 1.0] * (8760 / 2) }

      it 'has 4380 blackout hours' do
        expect(blackout.number_of_hours).to eq(4380)
      end

      it 'has correct blackout volume' do
        expect(blackout.volume).to eq(4380.0)
      end

      it 'has correct blackout peak' do
        expect(blackout.peak).to eq(1.0)
      end
    end

    context 'when net load includes minor negatives above -EPSILON' do
      let(:net_load) { [-eps / 2, -eps / 10, 0.0, 1.0] }

      it 'ignores them as blackout hours' do
        expect(blackout.number_of_hours).to eq(0)
      end

      it 'has zero blackout volume' do
        expect(blackout.volume).to eq(0)
      end

      it 'has zero blackout peak' do
        expect(blackout.peak).to eq(0.0)
      end
    end

    context 'with a few clear deficit values' do
      let(:net_load) { [-0.5, -2.0, 0.0, 1.0, -1.0] }

      it 'counts correct blackout hours' do
        expect(blackout.number_of_hours).to eq(3)
      end

      it 'calculates correct volume' do
        expect(blackout.volume).to eq(3.5)
      end

      it 'calculates correct peak' do
        expect(blackout.peak).to eq(2.0)
      end
    end
  end
end
