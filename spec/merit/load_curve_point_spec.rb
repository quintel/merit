require 'spec_helper'

module Merit

  describe LoadCurvePoint do

    describe '#new' do
      it 'should raise ArgumentError when new one is created with no load' do
        expect(->{LoadCurvePoint.new}).to raise_error ArgumentError
      end
      it 'should remember the load_value when created' do
        load_curve_point = LoadCurvePoint.new(1)
        expect(load_curve_point.load).to eql 1
      end
    end

  end #describe LoadCurvePoint

end

