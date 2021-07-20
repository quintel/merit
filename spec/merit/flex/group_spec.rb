# frozen_string_literal: true

require 'spec_helper'

describe Merit::Flex::ShareGroup do
  let(:participant_one) do
    Merit::Flex::BlackHole.new(
      key: :a,
      number_of_units: 1,
      group: :a,
      input_capacity_per_unit: 2.0
    )
  end

  let(:participant_two) do
    Merit::Flex::BlackHole.new(
      key: :b,
      number_of_units: 1,
      group: :a,
      input_capacity_per_unit: 2.0
    )
  end

  let(:group) do
    sorting = Merit::Sorting.by_sortable_cost

    Merit::Flex::Group.new(:a, sorting).tap do |group|
      group.insert(participant_one)
      group.insert(participant_two)
    end
  end

  describe '#simplify' do
    context 'with no participants' do
      it 'returns itself' do
        group = Merit::Flex::Group.new(:a)
        expect(group.simplify).to eq(group)
      end
    end

    context 'with one participant' do
      it 'returns the participant' do
        group = Merit::Flex::Group.new(:a)
        part = FactoryBot.build(:flex)

        group.insert(part)

        expect(group.simplify).to eq(part)
      end
    end

    context 'with two participants' do
      it 'returns itself' do
        group = Merit::Flex::Group.new(:a)
        group.insert(FactoryBot.build(:flex))
        group.insert(FactoryBot.build(:flex))

        expect(group.simplify).to eq(group)
      end
    end
  end

  context 'with two participants cap 2.0' do
    context 'when assigning 2.0' do
      let!(:assign) { group.assign_excess(0, 2.0) }

      it 'assigns 2 to participant one' do
        expect(participant_one.load_at(0)).to eq(-2)
      end

      it 'assigns nothing to participant two' do
        expect(participant_two.load_at(0)).to eq(0)
      end

      it 'returns 2' do
        expect(assign).to eq(2)
      end
    end

    context 'when assigning 5.0' do
      let!(:assign) { group.assign_excess(0, 5.0) }

      it 'assigns 2 to participant one' do
        expect(participant_one.load_at(0)).to eq(-2)
      end

      it 'assigns 2 to participant two' do
        expect(participant_two.load_at(0)).to eq(-2)
      end

      it 'returns 4' do
        expect(assign).to eq(4)
      end
    end

    context 'when assigning 10.0' do
      let!(:assign) { group.assign_excess(0, 10.0) }

      it 'assigns 2.0 to participant one' do
        expect(participant_one.load_at(0)).to eq(-2.0)
      end

      it 'assigns 2.0 to participant two' do
        expect(participant_two.load_at(0)).to eq(-2.0)
      end

      it 'returns 4.0' do
        expect(assign).to eq(4.0)
      end
    end
  end

  context 'when the participants swap order in point 1' do
    let(:participant_one) do
      Merit::Flex::Base.new(
        key: :a,
        output_capacity_per_unit: 2.0,
        number_of_units: 1,
        excess_share: 0.25,
        group: :a,
        input_capacity_per_unit: 2.0,
        cost_curve: [1.0, 2.0]
      )
    end

    let(:participant_two) do
      Merit::Flex::Base.new(
        key: :b,
        output_capacity_per_unit: 2.0,
        number_of_units: 1,
        excess_share: 0.75,
        group: :a,
        input_capacity_per_unit: 2.0,
        cost_curve: [2.0, 1.0]
      )
    end

    context 'when assigning 2.0' do
      before do
        group.assign_excess(0, 2.0)
        group.assign_excess(1, 2.0)
      end

      it 'assigns 2 to participant one in frame 0' do
        expect(participant_one.load_at(0)).to eq(-2)
      end

      it 'assigns nothing to participant two in frame 0' do
        expect(participant_two.load_at(0)).to eq(0)
      end

      it 'assigns nothing to participant one in frame 1' do
        expect(participant_one.load_at(1)).to eq(0)
      end

      it 'assigns 2 to participant two in frame 1' do
        expect(participant_two.load_at(1)).to eq(-2)
      end
    end

    context 'when assigning 10.0' do
      before do
        group.assign_excess(0, 10.0)
        group.assign_excess(1, 10.0)
      end

      it 'assigns 2 to participant one in frame 0' do
        expect(participant_one.load_at(0)).to eq(-2)
      end

      it 'assigns 2 to participant two in frame 0' do
        expect(participant_two.load_at(0)).to eq(-2)
      end

      it 'assigns 2 to participant one in frame 1' do
        expect(participant_one.load_at(1)).to eq(-2)
      end

      it 'assigns 2 to participant two in frame 1' do
        expect(participant_two.load_at(1)).to eq(-2)
      end
    end
  end
end
