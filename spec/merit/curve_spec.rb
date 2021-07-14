# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe Curve do
    let(:load_curve) { described_class.new((1..8760).to_a) }
    let(:load_curve2) { described_class.new((1..8760).to_a) }

    describe '#new' do
      it 'creates a Curve with 8760 values' do
        expect(load_curve.to_a.length).to eq(8760)
        expect(load_curve.to_a).to eql((1..8760).to_a)
      end

      context 'with an explicit length' do
        let(:curve) { described_class.new([], 100) }

        it 'iterates through the full length' do
          expect(curve.to_a.length).to eq(100)
          expect(curve.to_a.first).to be(0.0)
        end

        it 'uses the given length' do
          expect(curve.length).to be(100)
        end
      end
    end

    describe '#inspect' do
      it 'contains the number of load curve values' do
        expect(load_curve.inspect).to match('8760 values')
      end
    end

    describe '#draw' do
      it 'draws' do
        output = capture_stdout { load_curve.draw }
        expect(output).to be_a(String)
        expect(output.size).to be > 0
      end
    end

    describe '#to_a' do
      let(:curve) { described_class.new([3.0, 4.0, 0.0, 2.0]) }
      let(:array) { curve.to_a }

      it 'has the same length as the original values' do
        expect(array.length).to be(4)
      end

      it 'includes numerical values' do
        expect(array[0]).to be(3.0)
        expect(array[1]).to be(4.0)
        expect(array[3]).to be(2.0)
      end

      describe 'when the curve has an explicit length' do
        describe 'and the init values are shorter' do
          let(:curve) { described_class.new([3.0, 2.0], 4) }

          it 'pads the array with zeros' do
            expect(curve.to_a).to eq([3.0, 2.0, 0.0, 0.0])
          end
        end
      end
    end

    describe '#get' do
      let(:curve) { described_class.new([3.0, nil]) }

      it 'retrieves the value' do
        expect(curve.get(0)).to be(3.0)
      end

      it 'returns 0.0 if the value is nil' do
        expect(curve.get(1)).to be(0.0)
      end

      it 'returns 0.0 if no value is set' do
        expect(curve.get(2)).to be(0.0)
      end

      describe 'when the curve has an explicit length' do
        describe 'and the init values are shorter' do
          let(:curve) { described_class.new([3.0, 2.0], 10) }

          it 'returns an in-bounds value' do
            expect(curve.get(1)).to eq(2.0)
          end

          it 'returns 0.0 to an out-of-bounds element' do
            expect(curve.get(5)).to eq(0.0)
          end
        end
      end
    end

    describe '#[]' do
      let(:curve) { described_class.new([3.0, nil]) }

      it 'retrieves the value' do
        expect(curve[0]).to be(3.0)
      end

      it 'returns 0.0 if the value is nil' do
        expect(curve[1]).to be(0.0)
      end

      it 'returns 0.0 if no value is set' do
        expect(curve[2]).to be(0.0)
      end
    end

    describe '#set' do
      let(:curve) { described_class.new([3.0, nil]) }

      it 'sets the value' do
        curve.set(1, 1337)
        expect(curve.get(1)).to be(1337)
      end
    end

    describe '#[]=' do
      let(:curve) { described_class.new([3.0, nil]) }

      it 'sets the value' do
        curve[1] = 1337
        expect(curve.get(1)).to be(1337)
      end
    end

    describe '#-' do
      context 'with equal-length curves' do
        let(:left)  { described_class.new([1, 5.2, 3]) }
        let(:right) { described_class.new([2.0, 3, 2]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(-1.0)
          expect(curve.to_a[1]).to be(2.2)
          expect(curve.to_a[2]).to be(1)
        end
      end

      context 'with a different-length right curve' do
        let(:left)  { described_class.new([1, 4.2, 3]) }
        let(:right) { described_class.new([2.0]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(-1.0)
          expect(curve.to_a[1]).to be(4.2)
          expect(curve.to_a[2]).to be(3.0)
        end
      end

      context 'with a different-length left curve' do
        let(:left)  { described_class.new([2.0]) }
        let(:right) { described_class.new([1, 4.2, 3]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(1.0)
          expect(curve.to_a[1]).to be(-4.2)
          expect(curve.to_a[2]).to be(-3.0)
        end
      end

      context 'given a Numeric' do
        let(:left)  { described_class.new([1, 5.2, 3]) }
        let(:curve) { left - right }
        let(:right) { 2.0 }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(-1.0)
          expect(curve.to_a[1]).to be(3.2)
          expect(curve.to_a[2]).to be(1.0)
        end
      end
    end

    describe '#+' do
      context 'with equal-length curves' do
        let(:left)  { described_class.new([1, 5.2, 3]) }
        let(:right) { described_class.new([2.0, 3, 2]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(3.0)
          expect(curve.to_a[1]).to be(8.2)
          expect(curve.to_a[2]).to be(5)
        end
      end

      context 'with different-length right curve' do
        let(:left)  { described_class.new([1, 4.2, 3]) }
        let(:right) { described_class.new([2.0]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(3.0)
          expect(curve.to_a[1]).to be(4.2)
          expect(curve.to_a[2]).to be(3.0)
        end
      end

      context 'with different-length left curve' do
        let(:left)  { described_class.new([2.0]) }
        let(:right) { described_class.new([1, 4.2, 3]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(3.0)
          expect(curve.to_a[1]).to be(4.2)
          expect(curve.to_a[2]).to be(3.0)
        end
      end

      context 'given a Numeric' do
        let(:left)  { described_class.new([1, 5.2, 3]) }
        let(:curve) { left + right }
        let(:right) { 2.0 }

        it 'returns a Curve' do
          expect(curve).to be_a(described_class)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to be(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to be(3.0)
          expect(curve.to_a[1]).to be(7.2)
          expect(curve.to_a[2]).to be(5.0)
        end
      end
    end

    describe '#*' do
      context 'with same length' do
        let(:a) { described_class.new([1, 5.2, 3]) }
        let(:b) { described_class.new([2.0, 3, 2]) }
        let(:c) { a * b }

        it 'returns a Curve' do
          expect(c).to be_a(described_class)
        end

        it 'has as many values as the longest original' do
          expect(c.to_a.length).to be(3)
        end

        it 'multiplies each value' do
          expect(c.to_a[0]).to be_within(0.01).of(2.0)
          expect(c.to_a[1]).to be_within(0.01).of(15.6)
          expect(c.to_a[2]).to be_within(0.01).of(6.0)
        end
      end
    end

    describe '#rotate' do
      context 'with a curve [1, 2, 3, 4]' do
        let(:curve) { described_class.new([1, 2, 3, 4]) }

        it 'returns a Curve' do
          expect(curve.rotate(2)).to be_a(described_class)
        end

        it 'rotates the curve forwards' do
          expect(curve.rotate(1).to_a).to eq([2, 3, 4, 1])
        end

        it 'rotates the curve backwards' do
          expect(curve.rotate(-1).to_a).to eq([4, 1, 2, 3])
        end

        it 'may rotate by 0' do
          expect(curve.rotate(0).to_a).to eq([1, 2, 3, 4])
        end

        it 'returns a copy of when rotating by nothing' do
          rotated = curve.rotate(0)
          expect(rotated.object_id).not_to eq(curve.object_id)
        end
      end

      context 'when a curve [1, 2], length = 4, default = 0' do
        let(:curve) { described_class.new([1, 2], 4, 0) }

        it 'rotates the curve forwards' do
          expect(curve.rotate(1).to_a).to eq([2, 0, 0, 1])
        end

        it 'rotates the curve backwards' do
          expect(curve.rotate(-1).to_a).to eq([0, 1, 2, 0])
        end

        it 'may rotate by 0' do
          expect(curve.rotate(0).to_a).to eq([1, 2, 0, 0])
        end

        it 'returns a copy of when rotating by nothing' do
          rotated = curve.rotate(0)
          expect(rotated.object_id).not_to eq(curve.object_id)
        end

        it 'retains the original length' do
          expect(curve.rotate(1).length).to eq(4)
        end
      end
    end

    describe '.load_file' do
      it 'reads the contents of the given path' do
        curve   = described_class.load_file(fixture(:solar_pv))
        content = fixture(:solar_pv).read.split("\n").map(&:to_f)

        expect(curve.length).to eq(content.length)
        expect(curve.to_a).to eq(content)
      end

      it 'raises ENOENT when the path does not exist' do
        expect { described_class.load_file(fixture(:nope)) }.to raise_error(Errno::ENOENT)
      end
    end

    describe '.reader' do
      after { described_class.reader = Curve::Reader.new }

      context 'when no reader has been set' do
        before { described_class.instance_variable_set(:@reader, nil) }

        it 'returns the default Reader' do
          expect(described_class.reader).to     be_a(Curve::Reader)
          expect(described_class.reader).not_to be_a(Curve::CachingReader)
        end
      end

      context 'when setting a custom reader' do
        it 'sets the reader instance' do
          reader = Curve::CachingReader.new
          described_class.reader = reader

          expect(described_class.reader).to eql(reader)
        end
      end
    end
  end
end
