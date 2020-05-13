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
end