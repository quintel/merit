require 'spec_helper'

module Merit

  describe Order do

    let(:order){ Order.new }

    describe "#new" do
      it "should be able to create one" do
        Order.new
      end
    end

    describe "#load_curve" do
      it "should contain 2190 LoadCurvePoints" do
        expect(order.load_curve).to have(2190).points
      end
    end

    describe "#participants" do
      it 'should be able to add different types' do
        order.add(MustRunParticipant.new({}))
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0 participant")
        order.add(MustRunParticipant.new({}))
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
        order.add(MustRunParticipant.new({}))
        expect(order.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add(VolatileParticipant.new({}))
        expect(order.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add(DispatchableParticipant.new({}))
        expect(order.dispatchables).to_not be_empty
      end
    end

  end

end
