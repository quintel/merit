require 'spec_helper'

module Merit

  describe Participant do

    let(:participant){ Participant.new(key: :foo,
                                       effective_output_capacity: 1,
                                       marginal_costs: 2,
                                       availability: 3
                                      ) }

    describe '#new' do
      it 'should accept a hash with key/values' do
      end
      it 'should remember key, capacity, etc.' do
        expect(participant.key).to eql(:foo)
        expect(participant.effective_output_capacity).to eql(1)
        expect(participant.marginal_costs).to eql(2)
        expect(participant.availability).to eql(3)
      end
      it 'should raise MissingAttributeError when key misses' do
        expect(->{ Participant.new({}) }).to raise_error(MissingAttributeError)
      end
    end

    pending "refactoring" do
      describe "#load_curve" do
        context 'if demand is known' do
          it "should contain 8760 LoadCurvePoints" do
            order.total_demand = 1
            expect(order.load_curve).to have(8760).points
          end
          it "should scale correctly" do
            order.total_demand = 17.0
            expect(order.load_curve.load * 3600).to be_within(0.1).of(17)
          end
        end
        context 'if demand is UNknown' do
          it "should raise an error" do
            expect(->{ order.load_curve }).to raise_error(UnknownDemandError)
          end
        end
      end
    end

  end

end


