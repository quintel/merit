# frozen_string_literal: true

require 'spec_helper'

module Merit
  RSpec.describe Blackout do
    let(:blackout) { described_class.new(net_load) }

    context 'when the net load is constant 0' do
      let(:net_load)  { [0.0] * 8760 }

      it 'has no blackout hours' do
        expect(blackout.number_of_hours).to eq(0)
      end
    end

    context 'when the net load is constant 1' do
      let(:net_load)  { [1.0] * 8760 }

      it 'has no blackout hours' do
        expect(blackout.number_of_hours).to eq(0)
      end
    end

    context 'when the net load is constant -1' do
      let(:net_load)  { [-1.0] * 8760 }

      it 'has 8760 blackout hours' do
        expect(blackout.number_of_hours).to eq(8760)
      end
    end

    context 'when the net load alternates between -1 and 1' do
      let(:net_load)  { [-1.0, 1.0] * (8760 / 2) }

      it 'has 4380 blackout hours' do
        expect(blackout.number_of_hours).to eq(4380)
      end
    end
  end
end
