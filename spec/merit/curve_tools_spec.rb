# frozen_string_literal: true

require 'spec_helper'

describe Merit::CurveTools do
  describe '.add_curves' do
    context 'with two curves of [1, 2, 1, 2]' do
      let(:result) do
        described_class.add_curves([
          Merit::Curve.new([1.0, 2.0] * 2),
          Merit::Curve.new([1.0, 2.0] * 2),
        ])
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [2, 4, 2, 4]' do
        expect(result.take(4)).to eq([2, 4, 2, 4])
      end
    end

    context 'with two arrays of [1, 2, 1, 2]' do
      let(:result) do
        described_class.add_curves([
          [1.0, 2.0] * 2,
          [1.0, 2.0] * 2
        ])
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [2, 4, 2, 4]' do
        expect(result.take(4)).to eq([2, 4, 2, 4])
      end
    end

    context 'with an array and curve of [1, 2, 1, 2]' do
      let(:result) do
        described_class.add_curves([
          [1.0, 2.0] * 2,
          Merit::Curve.new([1.0, 2.0] * 2)
        ])
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [2, 4, 2, 4]' do
        expect(result.take(4)).to eq([2, 4, 2, 4])
      end
    end

    context 'with 26 curves alternating [1, 2, 1, 2] and [1, 2, 3, 4]' do
      let(:result) do
        c1 = Merit::Curve.new([1.0, 2.0, 1.0, 2.0])
        c2 = Merit::Curve.new([1.0, 2.0, 3.0, 4.0])

        described_class.add_curves([c1, c2] * 13)
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [26, 52, 52, 78]' do
        expect(result.take(4)).to eq([26, 52, 52, 78])
      end
    end
  end
end
