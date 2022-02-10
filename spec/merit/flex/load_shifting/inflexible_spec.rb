# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Flex::LoadShifting::Inflexible do
  let(:limiting_curve) { [1.0] * 8760 }

  let(:flexible) do
    instance_double(
      'Merit::Flex::LoadShifting::Flexible',
      mandatory_input_at: mandatory,
      assign_excess: mandatory
    )
  end

  let(:part) do
    described_class.new(
      key: :load_shaving_inflexible,
      flexible: flexible
    )
  end

  context 'when the flexible has no mandatory load' do
    let(:mandatory) { 0.0 }

    it 'has no load' do
      expect(part.load_at(0)).to eq(0)
    end

    it 'sets no load on the flexible' do
      part.load_at(0)
      expect(flexible).not_to have_received(:assign_excess)
    end
  end

  context 'when the flexible has mandatory load of 5.0' do
    let(:mandatory) { 5.0 }

    it 'has load of 5.0' do
      expect(part.load_at(0)).to eq(5.0)
    end

    it 'sets the load on the flexible' do
      part.load_at(0)
      expect(flexible).to have_received(:assign_excess).with(0, 5.0)
    end

    context 'when calling load_at a second time' do
      it 'returns the original value' do
        part.load_at(0)
        allow(flexible).to receive(:mandatory_input_at).with(0).and_return(10.0)

        expect(part.load_at(0)).to eq(5.0)
      end

      it 'does not change the flexible load again' do
        part.load_at(0)
        part.load_at(0)

        expect(flexible).to have_received(:assign_excess).once
      end
    end
  end

  context 'when re-requesting an earlier point before the calculation is finished' do
    let(:mandatory) { 5.0 }

    before do
      part.load_at(0)
      part.load_at(1)
    end

    it 'has load of 0.0' do
      expect(part.load_at(0)).to eq(0.0)
    end

    it 'does not re-set the load on the flexible' do
      part.load_at(0)
      expect(flexible).to have_received(:assign_excess).with(0, 5.0).once
    end
  end

  context 'when re-requesting an earlier point when the calculation is finished' do
    let(:mandatory) { 5.0 }

    before do
      part.load_at(Merit::POINTS - 1)
    end

    it 'has load of 0.0' do
      expect(part.load_at(0)).to eq(0.0)
    end

    it 'does not re-set the load on the flexible' do
      part.load_at(0)
      expect(flexible).not_to have_received(:assign_excess).with(0, 5.0)
    end
  end

  context 'when re-requesting the last point when the calculation is finished' do
    let(:mandatory) { 5.0 }

    before do
      part.load_at(Merit::POINTS - 1)
    end

    it 'has load of 5.0' do
      expect(part.load_at(Merit::POINTS - 1)).to eq(5.0)
    end
  end

  context 'when re-requesting the last point when the calculation is finished and rewound' do
    let(:mandatory) { 5.0 }

    before do
      part.load_at(Merit::POINTS - 1)
      part.load_at(0)
    end

    it 'has load of 0.0' do
      expect(part.load_at(Merit::POINTS - 1)).to eq(0)
    end
  end
end
