# frozen_string_literal: true

require 'spec_helper'

describe Merit::Curve::Reader do
  context 'when the file exists' do
    let(:result) { described_class.new.read(fixture(:solar_pv)) }

    it 'returns an array' do
      expect(result).to be_a(Array)
    end

    it 'has a value for each line in the file' do
      expect(result.length).to eq(8)
    end

    it 'parses lines to floats' do
      expect(result).to eq([
        0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7
      ])
    end
  end

  context 'when the file does not exist' do
    let(:result) { described_class.new.read('no_such_file.csv') }

    it 'raises Errno::ENOENT' do
      expect { result }.to raise_error(Errno::ENOENT)
    end
  end
end
