# frozen_string_literal: true

require 'spec_helper'

describe Merit::ParticipantSet do
  let(:must_run) do
    Merit::MustRunProducer.new(
      key: :must_run,
      marginal_costs: 1.0,
      full_load_hours: 8760,
      load_profile: Merit::Curve.new([1, 1])
    )
  end

  let(:dispatchable) do
    Merit::DispatchableProducer.new(
      key: :dispatchable,
      marginal_costs: 1.0,
      output_capacity_per_unit: 1.0,
      number_of_units: 1.0
    )
  end

  let(:user) do
    Merit::User.create(
      key: :user,
      load_profile: Merit::Curve.new([1, 1]),
      total_consumption: 1
    )
  end

  let(:participants) { described_class.new }

  context 'with one user and one must-run' do
    before do
      participants.add(user)
      participants.add(must_run)
    end

    it 'has one user' do
      expect(participants.users).to eq([user])
    end

    it 'has one always on' do
      expect(participants.always_on).to eq([must_run])
    end

    it 'has no transients' do
      expect(participants.transients).to eq([])
    end
  end

  context 'with one user and one transient' do
    before do
      participants.add(user)
      participants.add(dispatchable)
    end

    it 'has one user' do
      expect(participants.users).to eq([user])
    end

    it 'has no always ons' do
      expect(participants.always_on).to eq([])
    end

    it 'has one transient' do
      expect(participants.transients).to eq([dispatchable])
    end
  end

  context 'with one user, one must-run, and one transient' do
    before do
      participants.add(user)
      participants.add(must_run)
      participants.add(dispatchable)
    end

    it 'has one user' do
      expect(participants.users).to eq([user])
    end

    it 'has one always on' do
      expect(participants.always_on).to eq([must_run])
    end

    it 'has one transient' do
      expect(participants.transients).to eq([dispatchable])
    end
  end

  context 'with a must run added after a transient' do
    before do
      participants.add(dispatchable)
      participants.add(must_run)
    end

    it 'has no users' do
      expect(participants.users).to eq([])
    end

    it 'has one always on' do
      expect(participants.always_on).to eq([must_run])
    end

    it 'has one transient' do
      expect(participants.transients).to eq([dispatchable])
    end
  end

  context 'with four flex options, two belonging to a defined share group' do
    let(:f1) { FactoryBot.build(:flex, group: :a) }
    let(:f2) { FactoryBot.build(:flex, group: :b) }
    let(:f3) { FactoryBot.build(:flex, group: :b) }
    let(:f4) { FactoryBot.build(:flex, group: :c) }

    let(:group) { Merit::Flex::Group.new(:b) }

    before do
      participants.flex_groups.define(group)

      participants.add(f1)
      participants.add(f2)
      participants.add(f3)
      participants.add(f4)
    end

    it 'has three flexibility technologies' do
      expect(participants.flex.length).to eq(3)
    end

    it 'has flexibility options in the original order' do
      # Groups a and c are simplified to the participants.
      expect(participants.flex.map(&:key)).to eq([f1.key, :b, f4.key])
    end

    it 'has the group as a flexibility technology' do
      expect(participants.flex.to_a[1]).to be_a(Merit::Flex::Group)
    end

    it 'adds the flex technologies to the group' do
      group = participants.flex.to_a[1]
      expect(group.to_a).to eq([f2, f3])
    end

    it 'has the Group instance as a flexibility technology' do
      expect(participants.flex.to_a[1]).to eq(group)
    end
  end

  context 'with four flex options, two belonging to an undefined share group' do
    let(:f1) { FactoryBot.build(:flex, group: :a) }
    let(:f2) { FactoryBot.build(:flex, group: :b) }
    let(:f3) { FactoryBot.build(:flex, group: :b) }
    let(:f4) { FactoryBot.build(:flex, group: :c) }

    before do
      participants.add(f1)
      participants.add(f2)
      participants.add(f3)
      participants.add(f4)
    end

    it 'has four flexibility technologies' do
      expect(participants.flex.length).to eq(4)
    end

    it 'has flexibility options in the original order' do
      # Groups a and c are simplified to the participants.
      expect(participants.flex.map(&:key)).to eq(
        [f1.key, f2.key, f3.key, f4.key]
      )
    end
  end
end
