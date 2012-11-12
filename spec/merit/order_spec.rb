require 'spec_helper'

module Merit

  describe Order do

    let(:order){ Order.new }

    describe "#new" do
      it "should be able to create one" do
        Order.new
      end
    end

    describe "#add" do
      it 'should be able to add different types, which should be returned' do
        new_participant = MustRunParticipant.new({key: :foo})
        expect(order.add(new_participant)).to eql new_participant
      end
    end

    describe "#participants" do
      it 'should remember the added participants' do
        p1 = MustRunParticipant.new({key: :foo})
        p2 = MustRunParticipant.new({key: :bar})
        order.add(p1)
        order.add(p2)
        expect(order.participants).to eql [p1,p2]
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0 participant")
        order.add(MustRunParticipant.new({key: :foo}))
        expect(order.to_s).to match("1 participant")
      end
      it "shows the total demand"  do
        expect(order.to_s).to match("demand: not set")
        expect(Order.new(2000).to_s).to match("demand: 2000")
      end
    end

    describe "#must_runs" do
      it "must be empty at start" do
        expect(order.must_runs).to be_empty
      end
      it "should contain a new must run" do
        order.add(MustRunParticipant.new({key: :foo}))
        expect(order.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add(VolatileParticipant.new({key: :foo}))
        expect(order.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add(DispatchableParticipant.new({key: :foo}))
        expect(order.dispatchables).to_not be_empty
      end
      it "should be ordered by marginal_costs" do
        dp1 = DispatchableParticipant.new({key: :foo, marginal_costs: 2})
        dp2 = DispatchableParticipant.new({key: :bar, marginal_costs: 1})
        order.add(dp1)
        order.add(dp2)
        expect(order.dispatchables.first).to eql(dp2)
        expect(order.dispatchables.last).to  eql(dp1)
      end
    end

  end

end
