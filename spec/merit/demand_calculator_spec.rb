# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::DemandCalculator do
  let(:calculator) { described_class.create(users) }

  context 'with no dependent users' do
    let(:users) do
      [
        Merit::User.create(key: :a, load_curve: Merit::Curve.new([1.0, 2.0])),
        Merit::User.create(key: :b, load_curve: Merit::Curve.new([10.0, 20.0]))
      ]
    end

    it 'creates a DemandCalculator' do
      expect(calculator).to be_a(described_class)
    end

    it 'does not create a DemandCalculator::Dependent' do
      expect(calculator).not_to be_a(Merit::DemandCalculator::Dependent)
    end

    it 'calculates demand in point 0' do
      expect(calculator.demand_at(0)).to eq(11)
    end

    it 'calculates demand in point 1' do
      expect(calculator.demand_at(1)).to eq(22)
    end
  end

  context 'with a dependent users' do
    let(:users) do
      [
        Merit::User.create(key: :a, load_curve: Merit::Curve.new([1.0, 2.0])),
        Merit::User.create(key: :b, consumption_share: 20.0)
      ]
    end

    it 'creates a DemandCalculator::Dependent' do
      expect(calculator).to be_a(Merit::DemandCalculator::Dependent)
    end

    it 'calculates demand in point 0' do
      expect(calculator.demand_at(0)).to eq(21)
    end

    it 'calculates demand in point 1' do
      expect(calculator.demand_at(1)).to eq(42)
    end
  end
end
