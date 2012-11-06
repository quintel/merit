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
        order.add_must_run(:foo, :profile, 1,2,3,4)
        order.add_volatile(:foo, :profile, 1,2,3,4)
        order.add_dispatchable(:foo, :profile, 1,2)
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0")
        order.add_must_run(1,2,3,4,5,6)
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
        order.add_must_run(1,2,3,4,5,6)
        expect(order.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add_volatile(1,2,3,4,5,6)
        expect(order.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add_dispatchable(1,2,3,4)
        expect(order.dispatchables).to_not be_empty
      end
    end

  end

end
