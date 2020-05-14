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
end
