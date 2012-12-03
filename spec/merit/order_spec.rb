require 'spec_helper'

module Merit

  describe Order do

    let(:order){ Order.new }

    let(:p1) do
      DispatchableProducer.new(
        key:                       :foo,
        marginal_costs:            13.999791,
        output_capacity_per_unit:  0.1,
        number_of_units:           1,
        availability:              0.89,
        fixed_costs_per_unit:      222.9245208,
        fixed_om_costs_per_unit:   35.775
      )
    end

    let(:p2) do
      VolatileProducer.new(
        key:                       :bar,
        marginal_costs:            13.7,
        output_capacity_per_unit:  0.1,
        number_of_units:           1,
        availability:              0.89,
        fixed_costs_per_unit:      222.9245208,
        fixed_om_costs_per_unit:   35.775,
        load_profile_key:          :solar_pv,
        full_load_hours:           1000
      )
    end

    let(:p3) do
      MustRunProducer.new(
        key:                       :baz,
        marginal_costs:            101.1,
        output_capacity_per_unit:  0.1,
        number_of_units:           1,
        availability:              0.89,
        fixed_costs_per_unit:      222.9245208,
        fixed_om_costs_per_unit:   35.775,
        load_profile_key:          :solar_pv,
        full_load_hours:           1000
      )
    end

    let(:p4) do
      DispatchableProducer.new(
        key:                       :foo_cheaper,
        marginal_costs:            12.1,
        output_capacity_per_unit:  0.1,
        number_of_units:           1,
        availability:              0.89,
        fixed_costs_per_unit:      222.9245208,
        fixed_om_costs_per_unit:   35.775,
        load_profile_key:          :solar_pv,
        full_load_hours:           1000
      )
    end

    describe "#new" do
      it "should be able to create one" do
        Order.new
      end
    end

    describe "#add" do
      it 'should be able to add different types, which should be returned' do
        expect(order.add(p1)).to eql p1
      end

      it 'should set a reference to the order on the participant' do
        expect(order.add(p1).order).to eql order
      end
    end

    describe '#demand_at_at(point_in_time)' do
      it 'should return the sum of the load at of users' do
      end
    end

    describe "#participants" do
      it 'should remember the added participants' do
        order.add(p1)
        order.add(p2)
        expect(order.participants).to eql [p1,p2]
      end
    end

    describe '#price_at' do
      it 'should return the marginal cost of the price setting producer' do
        order.stub(:price_setting_producers) do
          Array.new(Merit::POINTS, p1)
        end
        expect(order.price_at(118)).to eql 13.999791
      end
    end

    describe '#price_curve' do
      before(:all) do
        order.stub(:price_at) { 1 }
      end
      it 'should be another instance of a Curve' do
        expect(order.price_curve).to be_a(LoadCurve)
      end
      it 'should have all ones' do
        expect(order.price_curve.to_a[118]).to eql 1
      end
    end

    describe '#producers' do
      it 'returns "always on" participants first' do
        dispatchable = p1
        volatile     = p2
        must_run     = p3

        order.add(dispatchable)
        order.add(volatile)
        order.add(must_run)

        expect(order.producers.last).to eql(dispatchable)
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0 producer")
        order.add(p1)
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
        order.add(p3)
        expect(order.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add(p2)
        expect(order.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add(p1)
        expect(order.dispatchables).to_not be_empty
      end
      it "should be ordered by marginal_costs" do
        order.add(p1)
        order.add(p4)
        expect(order.dispatchables.first).to eql(p4)
        expect(order.dispatchables.last).to  eql(p1)
      end
    end

    describe '#add'do
      context 'when the order has not been calculated' do
        it 'adds the participant to the order' do
          order.add(p1)
          expect(order.participants).to include(p1)
        end
      end

      context 'when the order has been calculated already' do
        it 'raises an error' do
          order.calculate

          expect { order.add(p1) }.
            to raise_error(Merit::LockedOrderError)
        end
      end
    end

    describe '#load_curves' do
      it 'returns an array of load curves' do
        order.add(p1)
        expect(order.load_curves).to be_a(Array)
      end

      it 'returns one member per producer' do
        order.add(p1)
        order.add(p2)

        expect(order.load_curves.first).to have(2).members
      end
    end

  end
end
