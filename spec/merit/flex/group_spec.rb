# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Flex::Group do
  describe '.from_collection' do
    let(:groups) { described_class.from_collection(Merit::Sorting.by_sortable_cost(participants)) }

    context 'when given no items' do
      let(:participants) { [] }

      it 'creates no groups' do
        expect(groups).to eq([])
      end
    end

    context 'with three items, two with the same price' do
      let(:participants) do
        [
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 15.0)
        ]
      end

      it 'returns two elements' do
        expect(groups.length).to eq(2)
      end

      it 'creates a group for the two price-eq participants' do
        expect(groups.first).to be_a(described_class)
      end

      it 'assigns participants to the first group' do
        expect(groups.first.to_a).to eq(participants[0..1])
      end

      it 'does not create a group for the solo participant' do
        expect(groups.last).to eq(participants.last)
      end
    end

    context 'when three items, all the same price and one is variable' do
      let(:participants) do
        [
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, cost_curve: [10.0])
        ]
      end

      it 'returns one element' do
        expect(groups.length).to eq(1)
      end
    end

    context 'when three items and one is variable' do
      let(:participants) do
        [
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, cost_curve: [12.0])
        ]
      end

      it 'returns two elements' do
        expect(groups.length).to eq(2)
      end
    end

    context 'with five items, two groups having the same price' do
      let(:participants) do
        [
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 10.0),
          FactoryBot.build(:flex, marginal_costs: 15.0),
          FactoryBot.build(:flex, marginal_costs: 20.0),
          FactoryBot.build(:flex, marginal_costs: 20.0)
        ]
      end

      it 'returns three elements' do
        expect(groups.length).to eq(3)
      end

      it 'creates a group for the first pair of price-eq participants' do
        expect(groups[0]).to be_a(described_class)
      end

      it 'assigns participants to the first group' do
        expect(groups[0].to_a).to eq(participants[0..1])
      end

      it 'does not create a group for the solo participant' do
        expect(groups[1]).to eq(participants[2])
      end

      it 'creates a group for the second pair of price-eq participants' do
        expect(groups[2]).to be_a(described_class)
      end

      it 'assigns participants to the second group' do
        expect(groups[2].to_a).to eq(participants[3..4])
      end
    end

    context 'with two items with the same price, both with infinite capacities' do
      let(:participants) do
        [
          FactoryBot.build(:flex, marginal_costs: 10.0, input_capacity_per_unit: Float::INFINITY),
          FactoryBot.build(:flex, marginal_costs: 10.0, input_capacity_per_unit: Float::INFINITY)
        ]
      end

      it 'returns two elements' do
        expect(groups.length).to eq(2)
      end

      it 'does not group the first participant' do
        expect(groups.first).to eq(participants.first)
      end

      it 'does not group the second participant' do
        expect(groups.last).to eq(participants.last)
      end
    end
  end

  context 'when initialized with two items' do
    let(:first) { FactoryBot.build(:flex, marginal_costs: 10.0, input_capacity_per_unit: 5.0) }
    let(:second) { FactoryBot.build(:flex, marginal_costs: 10.0, input_capacity_per_unit: 10.0) }
    let(:group) { described_class.new([first, second]) }

    it 'can iterate through each item' do
      items = []
      group.each { |part| items.push(part) }

      expect(items).to eq([first, second])
    end

    it 'can return the items in an array' do
      expect(group.to_a).to eq([first, second])
    end

    it 'calculates the unused input capacity of all members' do
      expect(group.unused_input_capacity_at(0)).to eq(15.0)
    end

    context 'when assigning 6 excess to members with no load' do
      let(:assign) { group.assign_excess(0, 6.0) }

      it 'returns 6' do
        expect(assign).to eq(6)
      end

      it 'assigns 2 to the first member' do
        expect { assign }.to change { first.load_at(0) }.from(0).to(-2)
      end

      it 'assigns 4 to the second member' do
        expect { assign }.to change { second.load_at(0) }.from(0).to(-4)
      end
    end

    context 'when assigning 0 excess to members with no load' do
      let(:assign) { group.assign_excess(0, 0.0) }

      it 'returns 0' do
        expect(assign).to be_zero
      end

      it 'assigns nothing to the first member' do
        expect { assign }.not_to change { first.load_at(0) }.from(0)
      end

      it 'assigns nothing to the second member' do
        expect { assign }.not_to change { second.load_at(0) }.from(0)
      end
    end

    context 'when assigning 60 excess to members with no load' do
      let(:assign) { group.assign_excess(0, 60.0) }

      it 'returns 15' do
        expect(assign).to eq(15)
      end

      it 'assigns 5 to the first member' do
        expect { assign }.to change { first.load_at(0) }.from(0).to(-5)
      end

      it 'assigns 10 to the second member' do
        expect { assign }.to change { second.load_at(0) }.from(0).to(-10)
      end
    end

    context 'when assigning 6 excess to members which are 50% loaded' do
      let(:assign) { group.assign_excess(0, 6.0) }

      before do
        first.assign_excess(0, 2.5)
        second.assign_excess(0, 5.0)
      end

      it 'returns 6' do
        expect(assign).to eq(6)
      end

      it 'increases the load of the first member to 4.5' do
        expect { assign }.to change { first.load_at(0) }.from(-2.5).to(-4.5)
      end

      it 'increases the load of the second member to 9' do
        expect { assign }.to change { second.load_at(0) }.from(-5).to(-9)
      end
    end

    context 'when assigning 6 excess to members which are fully-loaded' do
      let(:assign) { group.assign_excess(0, 6.0) }

      before do
        first.assign_excess(0, 5.0)
        second.assign_excess(0, 10.0)
      end

      it 'returns 0.0' do
        expect(assign).to eq(0)
      end

      it 'does not change the load of the first member' do
        expect { assign }.not_to change { first.load_at(0) }.from(-5)
      end

      it 'does not change the load of the second member' do
        expect { assign }.not_to change { second.load_at(0) }.from(-10)
      end
    end

    context 'when assigning 6 excess to members which are unevenly loaded' do
      let(:assign) { group.assign_excess(0, 6.0) }

      before do
        first.assign_excess(0, 1.0) # 4 remaining (80%)
        second.assign_excess(0, 1.0) # 9 remaining (90%)
      end

      it 'returns 6' do
        expect(assign).to eq(6)
      end

      it 'increases the load of the first member to 2.2' do
        assigned = 6.0 * (4.0 / (4 + 9))
        expect { assign }.to change { first.load_at(0) }.from(-1).to(-1 - assigned)
      end

      it 'increases the load of the second member to 6.8' do
        assigned = 6.0 * (9.0 / (4 + 9))
        expect { assign }.to change { second.load_at(0) }.from(-1).to(-1 - assigned)
      end
    end
  end
end
