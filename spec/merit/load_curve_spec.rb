require 'spec_helper'

module Merit

  describe LoadCurve do

    let(:load_curve) { LoadCurve.new((1..8760).to_a) }
    let(:load_curve2){ LoadCurve.new((1..8760).to_a) }

    describe '#new' do
      it 'should create a LoadCurve with 8760 values' do
        expect(load_curve.values).to have(8760).values
        expect(load_curve.values).to eql (1..8760).to_a
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

    describe '#-' do
      it 'should be able to substract one from the other' do
        load_curve1 = LoadCurve.new([1,2,3])
        load_curve2 = LoadCurve.new([0,1,2])
        sum = load_curve1 - load_curve2
        expect(sum).to be_a(LoadCurve)
        expect(sum.values).to eql [1,1,1]
      end
    end

    describe '#+' do
      it 'should be able to add one from the other' do
        load_curve1 = LoadCurve.new([1,2,3])
        load_curve2 = LoadCurve.new([0,1,2])
        sum = load_curve1 + load_curve2
        expect(sum).to be_a(LoadCurve)
        expect(sum.values).to eql [1,3,5]
      end
    end

  end

end
