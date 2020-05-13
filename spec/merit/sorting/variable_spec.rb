# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Sorting::Variable do
  let(:source) { [1, 2, 3, 4, 5] }

  let(:sorting) do
    described_class.new(source) do |el, point|
      (point % 2).zero? ? el : -el
    end
  end

  it 'returns the collection' do
    expect(sorting.at_point(0)).to eq(source)
  end

  it 'resorts the collection for each new point' do
    expect(sorting.at_point(1).dup)
      .to eq(sorting.at_point(0).dup.reverse)
  end

  it 'returns the same object each time' do
    expect(sorting.at_point(1).object_id).to eq(sorting.at_point(0).object_id)
  end

  context 'when adding a new item' do
    before { sorting.insert(6) }

    it 'sorts the item correctly in point 0' do
      expect(sorting.at_point(0)).to eq([1, 2, 3, 4, 5, 6])
    end

    it 'sorts the item correctly in point 1' do
      expect(sorting.at_point(1)).to eq([6, 5, 4, 3, 2, 1])
    end

    it 'ignores duplicate items' do
      sorting.insert(6)
      expect(sorting.at_point(0)).to eq([1, 2, 3, 4, 5, 6])
    end
  end

  describe '.by_sortable_cost' do
    let(:p1) { FactoryBot.build(:dispatchable, marginal_costs: 20.0) }
    let(:p2) { FactoryBot.build(:dispatchable, marginal_costs: 10.0) }

    let(:source) { [p1, p2] }
    let(:sorting) { described_class.by_sortable_cost(source) }

    it 'returns a Sorting::Variable' do
      expect(sorting).to be_a(described_class)
    end

    it 'sorts less expensive members first' do
      sorted = sorting.at_point(0)
      expect(sorted.index(p1)).to be > sorted.index(p2)
    end
  end

  describe '.by_sortable_cost_desc' do
    let(:p1) { FactoryBot.build(:dispatchable, marginal_costs: 20.0) }
    let(:p2) { FactoryBot.build(:dispatchable, marginal_costs: 10.0) }

    let(:source) { [p1, p2] }
    let(:sorting) { described_class.by_sortable_cost_desc(source) }

    it 'returns a Sorting::Variable' do
      expect(sorting).to be_a(described_class)
    end

    it 'sorts less expensive members first' do
      sorted = sorting.at_point(0)
      expect(sorted.index(p1)).to be < sorted.index(p2)
    end
  end
end
