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
        load_profile:              LoadProfile.new([0.01]),
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
        load_profile:              LoadProfile.new([0.01]),
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

    let(:p5) do
      DispatchableProducer.new(
        key:                       :foo_no_units,
        marginal_costs:            0,
        output_capacity_per_unit:  0.1,
        number_of_units:           0,
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
        expect(order.participants.to_a).to eql [p1,p2]
      end
    end

    describe '#price_curve' do
      it 'should default to a FirstUnloaded' do
        expect(order.price_curve).to be_a(PriceCurves::FirstUnloaded)
      end

      it 'should accept other price curves during initialization' do
        order.price_curve_class = PriceCurves::LastLoaded
        expect(order.price_curve).to be_a(PriceCurves::LastLoaded)
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

        expect(order.participants.producers.last).to eql(dispatchable)
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(order.to_s).to match("0 producer")
        order.add(p1)
        expect(order.to_s).to match("1 producer")
      end
    end

    describe "#must_runs" do
      it "must be empty at start" do
        expect(order.participants.must_runs).to be_empty
      end
      it "should contain a new must run" do
        order.add(p3)
        expect(order.participants.must_runs).to_not be_empty
      end
    end

    describe "#volatiles" do
      it "must be empty at start" do
        expect(order.participants.volatiles).to be_empty
      end
      it "should contain a new must run" do
        order.add(p2)
        expect(order.participants.volatiles).to_not be_empty
      end
    end

    describe "#dispatchables" do
      it "must be empty at start" do
        expect(order.participants.dispatchables).to be_empty
      end
      it "should contain a new must run" do
        order.add(p1)
        expect(order.participants.dispatchables).to_not be_empty
      end
      it "should be ordered by marginal_costs" do
        order.add(p1)
        order.add(p4)
        expect(order.participants.dispatchables.first).to eql(p4)
        expect(order.participants.dispatchables.last).to  eql(p1)
      end

      it "should be assigned the right position" do
        order.add(p1)
        order.add(p4)
        expect(order.participants.dispatchables.first.position).to eql(1)
        expect(order.participants.dispatchables.last.position).to  eql(2)
      end

      it "should assign -1 as position when capacity production is 0" do
        order.add(p5) # producer with 0 units
        expect(order.participants.dispatchables.first.position).to eql(-1)
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

        expect(order.load_curves.first.length).to eq(2)
      end
    end

    describe '.calculator=' do
      it 'sets the default calculator for calculations' do
        previous = Merit::Order.calculator
        new      = Merit::AveragingCalculator.new

        begin
          Merit::Order.calculator = new
          expect(Merit::Order.calculator).to eql(new)
        ensure
          Merit::Order.calculator = previous
        end
      end
    end

  end
end
