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
end
