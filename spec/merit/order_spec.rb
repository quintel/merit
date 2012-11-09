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
      context 'if demand is known' do
        it "should contain 8760 LoadCurvePoints" do
          order.total_demand = 1
          expect(order.load_curve).to have(8760).points
        end
        it "should have scaled correctly" do
          pending("exact definition of load profile from Chael")
          order.total_demand = 17.0
          expect(order.load_curve.load).to eql(17.0)
        end
      end
      context 'if demand is UNknown' do
        it "should raise an error" do
          expect(->{ order.load_curve }).to raise_error(UnknownDemandError)
        end
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
      it "should be ordered by marginal_costs" do
        dp1 = DispatchableParticipant.new({marginal_costs: 2})
        dp2 = DispatchableParticipant.new({marginal_costs: 1})
        order.add(dp1)
        order.add(dp2)
        expect(order.dispatchables.first).to eql(dp2)
        expect(order.dispatchables.last).to  eql(dp1)
      end
    end

  end

end
