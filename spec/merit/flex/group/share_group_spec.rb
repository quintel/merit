# frozen_string_literal: true

require 'spec_helper'

describe Merit::Flex::ShareGroup do
  let(:participant_one) do
    Merit::Flex::BlackHole.new(
      key: :a,
      output_capacity_per_unit: 2.0,
      number_of_units: 1,
      excess_share: 0.25,
      group: :a,
      input_capacity_per_unit: 2.0
    )
  end

  let(:participant_two) do
    Merit::Flex::BlackHole.new(
      key: :b,
      output_capacity_per_unit: 2.0,
      number_of_units: 1,
      excess_share: 0.75,
      group: :a,
      input_capacity_per_unit: 2.0
    )
  end

  let(:group) do
    described_class.new(:a).insert(participant_one).insert(participant_two)
  end

  context 'with two participants, share 0.25/0.75, cap 2.0' do
    context 'when assigning 2.0' do
      let!(:assign) { group.assign_excess(0, 2.0) }

      it 'assigns 0.5 to participant one' do
        expect(participant_one.load_curve.get(0)).to eq(-0.5)
      end

      it 'assigns 1.5 to participant two' do
        expect(participant_two.load_curve.get(0)).to eq(-1.5)
      end

      it 'returns 2.0' do
        expect(assign).to eq(2.0)
      end
    end

    context 'when assigning 5.0' do
      let!(:assign) { group.assign_excess(0, 5.0) }

      pending 'assigns 2.0 to participant one' do
        expect(participant_one.load_curve.get(0)).to eq(-2.0)
      end

      it 'assigns 2.0 to participant two' do
        expect(participant_two.load_curve.get(0)).to eq(-2.0)
      end

      pending 'returns 4.0' do
        expect(assign).to eq(4.0)
      end
    end

    context 'when assigning 10.0' do
      let!(:assign) { group.assign_excess(0, 10.0) }

      it 'assigns 2.0 to participant one' do
        expect(participant_one.load_curve.get(0)).to eq(-2.0)
      end

      it 'assigns 2.0 to participant two' do
        expect(participant_two.load_curve.get(0)).to eq(-2.0)
      end

      it 'returns 4.0' do
        expect(assign).to eq(4.0)
      end
    end
  end
end
