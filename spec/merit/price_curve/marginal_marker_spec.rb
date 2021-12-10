# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::PriceCurve::MarginalMarker do
  context 'when behaving as a consumer active in even hours' do
    let(:participants) do
      Merit::Sorting.by_sortable_cost_desc([
        FactoryBot.build(:flex, marginal_costs: 10.0),
        FactoryBot.build(:flex, marginal_costs: 20.0)
      ])
    end

    let(:marker) do
      described_class.consumer([true, false], participants)
    end

    it 'is active in hour 0' do
      expect(marker.active_at?(0)).to eq(true)
    end

    it 'is inactive in hour 1' do
      expect(marker.active_at?(1)).to eq(false)
    end

    it 'has a cost of 20.01 when no participant is active' do
      expect(marker.cost_at(0)).to eq(20.01)
    end

    it 'has a cost of 10.01 when the 20.00 participant is active' do
      participants.at_point(0).last.assign_excess(0, 1.0)
      expect(marker.cost_at(0)).to eq(10.01)
    end

    it 'has a cost of 10.01 when the both participants are active' do
      participants.at_point(0).first.assign_excess(0, 1.0)
      participants.at_point(0).last.assign_excess(0, 1.0)

      expect(marker.cost_at(0)).to eq(10.01)
    end
  end

  context 'when behaving as a consumer with no participants' do
    let(:participants) do
      Merit::Sorting.by_sortable_cost_desc([])
    end

    let(:marker) do
      described_class.consumer([true, false], participants)
    end

    it 'has a cost of 0 when no participant is active' do
      expect(marker.cost_at(0)).to eq(0)
    end
  end

  context 'when behaving as a producer active in even hours' do
    let(:participants) do
      Merit::Sorting.by_sortable_cost_desc([
        FactoryBot.build(:dispatchable, marginal_costs: 10.0),
        FactoryBot.build(:dispatchable, marginal_costs: 20.0)
      ])
    end

    let(:marker) do
      described_class.producer([true, false], participants)
    end

    it 'is active in hour 0' do
      expect(marker.active_at?(0)).to eq(true)
    end

    it 'is inactive in hour 1' do
      expect(marker.active_at?(1)).to eq(false)
    end

    it 'has a cost of 20.01 when no participant is active' do
      expect(marker.cost_at(0)).to eq(19.99)
    end

    it 'has a cost of 10.01 when the 20.00 participant is active' do
      participants.at_point(0).last.set_load(0, 1.0)
      expect(marker.cost_at(0)).to eq(9.99)
    end

    it 'has a cost of 10.01 when the both participants are active' do
      participants.at_point(0).first.set_load(0, 1.0)
      participants.at_point(0).last.set_load(0, 1.0)

      expect(marker.cost_at(0)).to eq(9.99)
    end
  end

  context 'when behaving as a producer with no participants' do
    let(:participants) do
      Merit::Sorting.by_sortable_cost_desc([])
    end

    let(:marker) do
      described_class.producer([true, false], participants)
    end

    it 'has a cost of 0 when no participant is active' do
      expect(marker.cost_at(0)).to eq(0)
    end
  end
end
