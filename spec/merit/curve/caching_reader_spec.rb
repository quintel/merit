# frozen_string_literal: true

require 'spec_helper'

describe Merit::Curve::CachingReader do
  let(:reader) { described_class.new }

  it 'reads the source file only once' do
    allow(File).to receive(:foreach).and_call_original

    reader.read(fixture('solar_pv'))
    reader.read(fixture('solar_pv'))
    reader.read(fixture('solar_pv'))

    # Merit calls foreach once - enum_for(:foreach) - which is then called again
    # when evalulating the enumerable.
    expect(File).to have_received(:foreach).exactly(2).times
  end

  it 'caches based on path, not filename' do
    one = reader.read(fixture('solar_pv'))
    two = reader.read(fixture('subdir/solar_pv'))

    expect(one).not_to eql(two)
  end
end
