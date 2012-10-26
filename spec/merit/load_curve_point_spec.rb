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

    describe '#running_participants' do

      xit 'should be able to calculate which participants are running' do
        load_curve_point = LoadCurvePoint.new(100)
        expect(load_curve_point.running_participants).to have(3).participants
      end
    end

  end

end

