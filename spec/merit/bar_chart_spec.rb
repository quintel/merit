require 'spec_helper'

module Merit
  describe BarChart do

    let(:barchart0)   { BarChart.new([0,0,0],3,3) }
    let(:barchart_neg){ BarChart.new([-3,-2,1],3,3) }

    describe 'reduced_values' do
      it 'should be able to handle small sizes' do
        expect(barchart0.reduced_values).to eql [0.0,0.0,0.0]
      end
      it 'should be able to handle negative values' do
        expect(barchart_neg.reduced_values).to eql [-3.0,-2.0,1.0]
      end
    end

    describe '#drawing' do
      it 'should be able to draw a chart with just values 0' do
        expect(barchart0.drawing).to eql "--- 0.00e+00\n--- 0.00e+00\nooo 0.00e+00"
      end
      it 'should be able to draw a chart with negative values' do
        pending "implemenation of negative numbers"
        expect(barchart0.drawing).to eql "--o 0.00e+00\n-o- 0.00e+00\no-- 0.00e+00"
      end
    end #describe #drawing
  end #describe BarChart
end #module Merit
