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
end
