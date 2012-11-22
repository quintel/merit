require 'spec_helper'

module Merit

  describe LoadCurve do

    let(:load_curve) { LoadCurve.new((1..8760).to_a) }
    let(:load_curve2){ LoadCurve.new((1..8760).to_a) }

    describe '#new' do
      it 'should create a LoadCurve with 8760 values' do
        expect(load_curve.to_a).to have(8760).values
        expect(load_curve.to_a).to eql (1..8760).to_a
      end

      context 'with an explicit length' do
        let(:curve) { LoadCurve.new([], 100) }

        it 'iterates through the full length' do
          expect(curve.to_a).to have(100).members
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
        expect(->{ load_curve.draw }).to_not raise_error
      end
    end

    describe '#to_a' do
      let(:curve) { LoadCurve.new([3.0, 4.0, nil, 2.0]) }
      let(:array) { curve.to_a }

      it 'has the same length as the original values' do
        expect(array.length).to eql(4)
      end

      it 'includes numerical values' do
        expect(array[0]).to eql(3.0)
        expect(array[1]).to eql(4.0)
        expect(array[3]).to eql(2.0)
      end

      it 'converts nils to 0.0' do
        expect(array[2]).to eql(0.0)
      end
    end # to_a

    describe '#get' do
      let(:curve) { LoadCurve.new([3.0, nil]) }

      it 'retrieves the value' do
        expect(curve.get(0)).to eql(3.0)
      end

      it 'returns 0.0 if the value is nil' do
        expect(curve.get(1)).to eql(0.0)
      end

      it 'returns 0.0 if no value is set' do
        expect(curve.get(2)).to eql(0.0)
      end
    end # get

    describe '#set' do
      let(:curve) { LoadCurve.new([3.0, nil]) }

      it 'sets the value' do
        curve.set(1, 1337)
        expect(curve.get(1)).to eql(1337)
      end
    end # set

    describe '#-' do
      context 'with equal-length curves' do
        let(:left)  { LoadCurve.new([1, 5.2, 3]) }
        let(:right) { LoadCurve.new([2.0, 3, 2]) }
        let(:curve) { left - right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
        let(:left)  { LoadCurve.new([1, 4.2, 3]) }
        let(:right) { LoadCurve.new([2.0]) }
        let(:curve) { left - right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
        let(:left)  { LoadCurve.new([2.0]) }
        let(:right) { LoadCurve.new([1, 4.2, 3]) }
        let(:curve) { left - right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
    end # #-

    describe '#+' do
      context 'with equal-length curves' do
        let(:left)  { LoadCurve.new([1, 5.2, 3]) }
        let(:right) { LoadCurve.new([2.0, 3, 2]) }
        let(:curve) { left + right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
        let(:left)  { LoadCurve.new([1, 4.2, 3]) }
        let(:right) { LoadCurve.new([2.0]) }
        let(:curve) { left + right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
        let(:left)  { LoadCurve.new([2.0]) }
        let(:right) { LoadCurve.new([1, 4.2, 3]) }
        let(:curve) { left + right }

        it 'returns a LoadCurve' do
          expect(curve).to be_a(LoadCurve)
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
    end # #+

  end

end
