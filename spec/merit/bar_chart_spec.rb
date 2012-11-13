require 'spec_helper'

module Merit
  describe BarChart do

    let(:barchart0)   { BarChart.new([0,0,0],3,3) }

    describe 'reduced_values' do
      it 'should be able to handle small sizes' do
        expect(barchart0.reduced_values).to eql [0.0,0.0,0.0]
      end
    end

    describe '#drawing' do
      it 'should be able to draw a chart with just values 0' do
        expect(barchart0.drawing).to eql "--- 0.00e+00\n--- 0.00e+00\nooo 0.00e+00"
      end
    end #describe #drawing
  end #describe BarChart
end #module Merit
