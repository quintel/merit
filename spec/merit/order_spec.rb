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
        new_participant = MustRunProducer.new({key: :foo})
        expect(order.add(new_participant)).to eql new_participant
      end
    end

    describe '#demand_at_at(point_in_time)' do
      it 'should return the sum of the load at of users' do
      end
    end

    describe "#participants" do
      it 'should remember the added participants' do
        p1 = MustRunProducer.new({key: :foo})
        p2 = MustRunProducer.new({key: :bar})
        order.add(p1)
        order.add(p2)
        expect(order.participants).to eql [p1,p2]
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0 producer")
        order.add(MustRunProducer.new({key: :foo}))
        expect(order.to_s).to match("1 producer")
      end
      it "shows the total demand"  do
        expect(order.to_s).to match("0 user")
        expect(Order.new(2000).to_s).to match("1 user")
      end
    end

    describe "#must_runs" do
      it "must be empty at start" do
        expect(order.must_runs).to be_empty
      end
      it "should contain a new must run" do
        order.add(MustRunProducer.new({key: :foo}))
        expect(order.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add(VolatileProducer.new({key: :foo}))
        expect(order.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add(DispatchableProducer.new({key: :foo}))
        expect(order.dispatchables).to_not be_empty
      end
      it "should be ordered by marginal_costs" do
        dp1 = DispatchableProducer.new({key: :foo, marginal_costs: 2})
        dp2 = DispatchableProducer.new({key: :bar, marginal_costs: 1})
        order.add(dp1)
        order.add(dp2)
        expect(order.dispatchables.first).to eql(dp2)
        expect(order.dispatchables.last).to  eql(dp1)
      end
    end

  end

end
