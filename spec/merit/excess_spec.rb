require 'spec_helper'

module Merit
  describe Excess do
    let(:merit_order) { Order.new }
    let(:excess) { Excess.new(merit_order) }

    before do
      expect(excess).to receive(:production)
        .and_return(production)

      expect(excess).to receive(:consumption)
        .and_return(consumption)
    end

    context "empty curves" do
      let(:production) {  Curve.new([0, 0, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(1)).to eq(0)
      end
    end

    context "one event with a duration of 1 hour" do
      let(:production) {  Curve.new([0, 1, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(1)).to eq(1)
      end
    end

    context "one event of a duration of 2 hours" do
      let(:production) {  Curve.new([1, 1, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(2)).to eq(1)
      end
    end

    context "1 events of a duration of 2 hours" do
      let(:production) {  Curve.new([1, 1, 1, 1, 0]) }
      let(:consumption) { Curve.new([0, 0, 0, 0, 0]) }

      (2..4).each do |number|
        it 'determines the excess of a chart' do
          expect(excess.number_of_events(number)).to eq(1)
        end
      end

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(5)).to eq(0)
      end
    end

    context "2 events of a duration of 2 hours" do
      let(:production) {  Curve.new([1, 1, 0, 1, 1]) }
      let(:consumption) { Curve.new([0, 0, 0, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(2)).to eq(2)
      end
    end

    context "1 event of a duration of 5 hours" do
      let(:production) {  Curve.new(Array.new(14, 1)) }
      let(:consumption) { Curve.new(Array.new(14, 0)) }

      it 'determines the excess of a chart' do
        expect(excess.number_of_events(5)).to eq(1)
      end
    end
  end
end
