require 'spec_helper'

module Merit

  describe LoadCurve do

    let(:load_curve){ LoadCurve.new((1..8760).to_a) }

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

  end

end
