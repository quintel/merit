# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Sorting::Variable do
  let(:source) { [1, 2, 3, 4, 5] }
  let(:sort_key) { ->(el, point) { (point % 2).zero? ? el : 10 - el } }
  let(:selector) { ->(_) { true } }
  let(:config) { Merit::Sorting::Config.new(sort_key, selector) }

  let(:sorting) { described_class.new(source, config) }

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

  it 'resorts the collection with every possible input permutation' do
    # This is a sanity check test, to ensure that no matter which order the
    # items are originally in, that they are always sorted correctly.
    source.permutation.each do |input|
      sorting = described_class.new(input, config)
      expect(sorting.at_point(0)).to eq(source)
    end
  end

  # In this case, with few variable items the binary search insert it used.
  context 'with items <= 6 considered fixed, > 6 considered variable' do
    let(:source) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
    let(:selector) { ->(el) { el > 6 } }

    let(:sort_key) do
      # The "fixed" items must return keys in the same order for every point,
      # otherwise the binary search will not work as expected.
      ->(el, point) { selector.call(el) && point.positive? ? 100 - el : el }
    end

    it 'returns the collection' do
      expect(sorting.at_point(0)).to eq(source)
    end

    it 'sorts the collection in point 0' do
      expect(sorting.at_point(0).dup).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    it 'resorts the collection in point 1' do
      # The variable items (>6) are reversed by the sort_key.
      expect(sorting.at_point(1).dup).to eq([1, 2, 3, 4, 5, 6, 10, 9, 8, 7])
    end

    it 'returns the same object each time' do
      expect(sorting.at_point(1).object_id).to eq(sorting.at_point(0).object_id)
    end

    it 'does not use simple sort' do
      expect(sorting.simple_sort?).to be(false)
    end
  end

  # In this case, the simple sort is used.
  context 'with items <= 2 considered fixed, > 2 considered variable' do
    let(:source) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
    let(:selector) { ->(el) { el > 2 } }

    let(:sort_key) do
      # The "fixed" items must return keys in the same order for every point,
      # otherwise the binary search will not work as expected.
      ->(el, point) { selector.call(el) && point.positive? ? 100 - el : el }
    end

    it 'returns the collection' do
      expect(sorting.at_point(0)).to eq(source)
    end

    it 'sorts the collection in point 0' do
      expect(sorting.at_point(0).dup).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    it 'resorts the collection in point 1' do
      # The variable items (>2) are reversed by the sort_key.
      expect(sorting.at_point(1).dup).to eq([1, 2, 10, 9, 8, 7, 6, 5, 4, 3])
    end

    it 'returns the same object each time' do
      expect(sorting.at_point(1).object_id).to eq(sorting.at_point(0).object_id)
    end

    it 'does uses simple sort' do
      expect(sorting.simple_sort?).to be(true)
    end
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

  context 'when initialized without a sort block' do
    it 'raises a SortBlockRequired error' do
      expect { described_class.new([], Merit::Sorting::Config.new(nil, nil)) }
        .to raise_error(Merit::SortBlockRequired)
    end
  end
end
