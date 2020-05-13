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
end
