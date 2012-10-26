require 'spec_helper'

module Merit

  describe LoadCurve do

    let(:load_curve){ LoadCurve.create((1..8760).to_a) }

    describe '#create' do
      it 'should create a LoadCurve with 8760 points' do
        expect(load_curve.points).to have(8760).load_curve_points
        expect(load_curve.points.map(&:load)).to eql (1..8760).to_a
      end
    end

    describe '#inspect' do
      it 'should contain the number of load curve points' do
        expect(load_curve.inspect).to match '8760 Points'
      end
    end

  end

end
