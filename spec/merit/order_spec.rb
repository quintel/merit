require 'spec_helper'

module Merit

  describe Order do

    let(:order){ Order.new }

    describe "#new" do
      it "should be able to create one" do
        Order.new
      end
    end

    describe "#add_participant" do
      it "should be able to add a participant with full load hours" do
        order.add_participant(:a,:b,1,2,0.9)
        expect(order.participants).to have(1).participant
        expect(order.participants.first.full_load_hours).to be_nil
      end
      it "should be able to add a participant without full load hours" do
        order.add_participant(:a,:b,1,2,0.9,1000)
        expect(order.participants).to have(1).participant
        expect(order.participants.first.full_load_hours).to_not be_nil
      end
      it "should set attributes correctly" do
        participant = order.add_participant(:a,:b,1,2,0.9,8760)
        expect(participant.key).to             eql(:a)
        expect(participant.type).to            eql(:b)
        expect(participant.marginal_costs).to  eql(1)
        expect(participant.capacity).to        eql(2)
        expect(participant.availability).to    eql(0.9)
        expect(participant.full_load_hours).to eql(8760)
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0")
        order.add_participant(Participant.new)
        expect(order.to_s).to match("1")
      end
    end

  end

end
