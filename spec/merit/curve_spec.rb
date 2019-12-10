require 'spec_helper'

module Merit

  describe Curve do

    let(:load_curve) { Curve.new((1..8760).to_a) }
    let(:load_curve2){ Curve.new((1..8760).to_a) }

    describe '#new' do
      it 'should create a Curve with 8760 values' do
        expect(load_curve.to_a.length).to eq(8760)
        expect(load_curve.to_a).to eql((1..8760).to_a)
      end

      context 'with an explicit length' do
        let(:curve) { Curve.new([], 100) }

        it 'iterates through the full length' do
          expect(curve.to_a.length).to eq(100)
          expect(curve.to_a.first).to eql(0.0)
        end

        it 'uses the given length' do
          expect(curve.length).to eql(100)
        end
      end
    end

    describe '#inspect' do
      it 'should contain the number of load curve values' do
        expect(load_curve.inspect).to match '8760 values'
      end
    end

    describe '#draw' do
      it 'should draw' do
        output = capture_stdout { load_curve.draw }
        expect(output).to be_a(String)
        expect(output.size).to be > 0
      end
    end

    describe '#to_a' do
      let(:curve) { Curve.new([3.0, 4.0, 0.0, 2.0]) }
      let(:array) { curve.to_a }

      it 'has the same length as the original values' do
        expect(array.length).to eql(4)
      end

      it 'includes numerical values' do
        expect(array[0]).to eql(3.0)
        expect(array[1]).to eql(4.0)
        expect(array[3]).to eql(2.0)
      end

      describe 'when the curve has an explicit length' do
        describe 'and the init values are shorter' do
          let(:curve) { Curve.new([3.0, 2.0], 4) }

          it 'pads the array with zeros' do
            expect(curve.to_a).to eq([3.0, 2.0, 0.0, 0.0])
          end
        end # and the init values are shorter
      end # when the curve has an explicit length
    end # to_a

    describe '#get' do
      let(:curve) { Curve.new([3.0, nil]) }

      it 'retrieves the value' do
        expect(curve.get(0)).to eql(3.0)
      end

      it 'returns 0.0 if the value is nil' do
        expect(curve.get(1)).to eql(0.0)
      end

      it 'returns 0.0 if no value is set' do
        expect(curve.get(2)).to eql(0.0)
      end

      describe 'when the curve has an explicit length' do
        describe 'and the init values are shorter' do
          let(:curve) { Curve.new([3.0, 2.0], 10) }

          it 'returns an in-bounds value' do
            expect(curve.get(1)).to eq(2.0)
          end

          it 'returns 0.0 to an out-of-bounds element' do
            expect(curve.get(5)).to eq(0.0)
          end
        end # and the init values are shorter
      end # when the curve has an explicit length
    end # get

    describe '#[]' do
      let(:curve) { Curve.new([3.0, nil]) }

      it 'retrieves the value' do
        expect(curve[0]).to eql(3.0)
      end

      it 'returns 0.0 if the value is nil' do
        expect(curve[1]).to eql(0.0)
      end

      it 'returns 0.0 if no value is set' do
        expect(curve[2]).to eql(0.0)
      end
    end

    describe '#set' do
      let(:curve) { Curve.new([3.0, nil]) }

      it 'sets the value' do
        curve.set(1, 1337)
        expect(curve.get(1)).to eql(1337)
      end
    end # set

    describe '#[]=' do
      let(:curve) { Curve.new([3.0, nil]) }

      it 'sets the value' do
        curve[1] = 1337
        expect(curve.get(1)).to eql(1337)
      end
    end # set

    describe '#-' do
      context 'with equal-length curves' do
        let(:left)  { Curve.new([1, 5.2, 3]) }
        let(:right) { Curve.new([2.0, 3, 2]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(-1.0)
          expect(curve.to_a[1]).to eql(2.2)
          expect(curve.to_a[2]).to eql(1)
        end
      end # with equal-length curves

      context 'with a different-length right curve' do
        let(:left)  { Curve.new([1, 4.2, 3]) }
        let(:right) { Curve.new([2.0]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(-1.0)
          expect(curve.to_a[1]).to eql(4.2)
          expect(curve.to_a[2]).to eql(3.0)
        end
      end # with a different-length right curve

      context 'with a different-length left curve' do
        let(:left)  { Curve.new([2.0]) }
        let(:right) { Curve.new([1, 4.2, 3]) }
        let(:curve) { left - right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(1.0)
          expect(curve.to_a[1]).to eql(-4.2)
          expect(curve.to_a[2]).to eql(-3.0)
        end
      end # with a different-length left curve

      context 'given a Numeric' do
        let(:left)  { Curve.new([1, 5.2, 3]) }
        let(:curve) { left - right }
        let(:right) { 2.0 }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(-1.0)
          expect(curve.to_a[1]).to eql(3.2)
          expect(curve.to_a[2]).to eql(1.0)
        end
      end # given a Numeric
    end # #-

    describe '#+' do
      context 'with equal-length curves' do
        let(:left)  { Curve.new([1, 5.2, 3]) }
        let(:right) { Curve.new([2.0, 3, 2]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(3.0)
          expect(curve.to_a[1]).to eql(8.2)
          expect(curve.to_a[2]).to eql(5)
        end
      end # with equal-length curves

      context 'with different-length right curve' do
        let(:left)  { Curve.new([1, 4.2, 3]) }
        let(:right) { Curve.new([2.0]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(3.0)
          expect(curve.to_a[1]).to eql(4.2)
          expect(curve.to_a[2]).to eql(3.0)
        end
      end # with different-length right curve

      context 'with different-length left curve' do
        let(:left)  { Curve.new([2.0]) }
        let(:right) { Curve.new([1, 4.2, 3]) }
        let(:curve) { left + right }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the longest original' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(3.0)
          expect(curve.to_a[1]).to eql(4.2)
          expect(curve.to_a[2]).to eql(3.0)
        end
      end # with different-length left curve

      context 'given a Numeric' do
        let(:left)  { Curve.new([1, 5.2, 3]) }
        let(:curve) { left + right }
        let(:right) { 2.0 }

        it 'returns a Curve' do
          expect(curve).to be_a(Curve)
        end

        it 'has as many values as the originals' do
          expect(curve.to_a.length).to eql(3)
        end

        it 'subtracts each value' do
          expect(curve.to_a[0]).to eql(3.0)
          expect(curve.to_a[1]).to eql(7.2)
          expect(curve.to_a[2]).to eql(5.0)
        end
      end # given a Numeric
    end # #+

    describe '#*' do
      context 'with same length' do
        let(:a) { Curve.new([1, 5.2, 3]) }
        let(:b) { Curve.new([2.0, 3, 2]) }
        let(:c) { a * b }

        it 'should return a Curve' do
          expect(c).to be_a(Curve)
        end

        it 'has as many values as the longest original' do
          expect(c.to_a.length).to eql(3)
        end

        it 'multiplies each value' do
          expect(c.to_a[0]).to be_within(0.01).of(2.0)
          expect(c.to_a[1]).to be_within(0.01).of(15.6)
          expect(c.to_a[2]).to be_within(0.01).of(6.0)
        end
      end
    end # *

    describe '.load_file' do
      it 'reads the contents of the given path' do
        curve   = Curve.load_file(fixture(:solar_pv))
        content = fixture(:solar_pv).read.split("\n").map(&:to_f)

        expect(curve.length).to eq(content.length)
        expect(curve.to_a).to eq(content)
      end

      it 'raises ENOENT when the path does not exist' do
        expect { Curve.load_file(fixture(:nope)) }.to raise_error(Errno::ENOENT)
      end
    end # .load_file

    describe '.reader' do
      after { Curve.reader = Curve::Reader.new }

      context 'when no reader has been set' do
        before { Curve.instance_variable_set(:@reader, nil) }

        it 'returns the default Reader' do
          expect(Curve.reader).to     be_a(Curve::Reader)
          expect(Curve.reader).not_to be_a(Curve::CachingReader)
        end
      end

      context 'when setting a custom reader' do
        it 'sets the reader instance' do
          reader = Curve::CachingReader.new
          Curve.reader = reader

          expect(Curve.reader).to eql(reader)
        end
      end
    end
  end
end
