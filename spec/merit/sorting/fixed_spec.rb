# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Sorting::Fixed do
  let(:source) { [1, 2, 3, 4, 5] }
  let(:sorting) { described_class.new(source) }

  it 'returns the collection' do
    expect(sorting.at_point(0)).to eq(source)
  end

  it 'returns the collection in the same order each time' do
    expect(sorting.at_point(1)).to eq(sorting.at_point(0))
  end

  it 'accepts a new item with #add' do
    expect { sorting.insert(6) }
      .to change { sorting.at_point(0) }
      .from([1, 2, 3, 4, 5])
      .to([1, 2, 3, 4, 5, 6])
  end

  it 'ignores duplicate items' do
    sorting.insert(1)
    expect(sorting.at_point(0)).to eq([1, 2, 3, 4, 5])
  end

  context 'when given a sorting block' do
    it 'sorts the items the first time at_point is called' do
      sorting = described_class.new([5, 4, 3, 2, 1]) { |item, _| item }
      expect(sorting.at_point(0)).to eq([1, 2, 3, 4, 5])
    end

    it 'does not resort each item on subsequent calls to the same point' do
      sorting = described_class.new((1..1000).to_a) { |*| rand }
      expect(sorting.at_point(0)).to eq(sorting.at_point(0))
    end

    it 'does not resort the collection when calling with different points' do
      sorting = described_class.new((1..1000).to_a) { |*| rand }
      expect(sorting.at_point(1)).to eq(sorting.at_point(0))
    end
  end

  describe '.by_sortable_cost' do
    let(:p1) { FactoryBot.build(:dispatchable, marginal_costs: 20.0) }
    let(:p2) { FactoryBot.build(:dispatchable, marginal_costs: 10.0) }

    let(:source) { [p1, p2] }
    let(:sorting) { described_class.by_sortable_cost(source) }

    it 'returns a Sorting::Fixed' do
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

    it 'returns a Sorting::Fixed' do
      expect(sorting).to be_a(described_class)
    end

    it 'sorts less expensive members first' do
      sorted = sorting.at_point(0)
      expect(sorted.index(p1)).to be < sorted.index(p2)
    end
  end
end
