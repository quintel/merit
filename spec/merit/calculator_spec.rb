require 'spec_helper'

module Merit
  describe 'Calculations' do
    let(:order) do
      Order.new.tap do |order|
        order.add(dispatchable)
        order.add(volatile)
        order.add(volatile_two)
        order.add(User.new(key: :total_demand, total_consumption: 6.4e6))
      end
    end

    let(:volatile) do
      VolatileProducer.new(
        key:                       :volatile,
        load_profile_key:          :industry_chp,
        effective_output_capacity: 0.1,
        availability:              0.95,
        number_of_units:           1
      )
    end

    let(:volatile_two) do
      VolatileProducer.new(
        key:                       :volatile_two,
        load_profile_key:          :solar_pv,
        effective_output_capacity: 0.1,
        availability:              0.95,
        number_of_units:           1
      )
    end

    let(:dispatchable) do
      DispatchableProducer.new(
        key:                       :dispatchable,
        marginal_costs:            13.999791,
        effective_output_capacity: 0.1,
        number_of_units:           1,
        availability:              0.89
      )
    end

    context 'with an excess of demand' do
      before { Calculator.new.calculate(order) }

      it 'sets the load profile values of the first producer' do
        load_value = dispatchable.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(dispatchable.max_load_at(0))
      end

      it 'sets the load profile values of the second producer' do
        load_value = volatile.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile.max_load_at(0))
      end

      it 'sets the load profile values of the third producer' do
        load_value = volatile_two.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile_two.max_load_at(0))
      end
    end

    context 'with an excess of supply' do
      let(:dispatchable) do
        DispatchableProducer.new(
          key: :dispatchable,
          marginal_costs:            13.999791,
          effective_output_capacity: 0.1,
          number_of_units:           2,
          availability:              0.89
        )
      end

      before { Calculator.new.calculate(order) }

      it 'sets the load profile values of the first producer' do
        load_value = dispatchable.load_curve.get(0)

        demand = order.users.first.load_at(0)
        demand -= volatile.max_load_at(0)
        demand -= volatile_two.max_load_at(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(demand)
      end

      it 'sets the load profile values of the second producer' do
        load_value = volatile.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile.max_load_at(0))
      end

      it 'sets the load profile values of the third producer' do
        load_value = volatile_two.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile_two.max_load_at(0))
      end
    end

    describe 'with QuantizingCalculator' do
      it 'should set a value for each load point' do
        # Set an excess of demand so that the dispatchable is running
        # all the time.
        order.users.first.total_consumption = 6.4e7

        QuantizingCalculator.new.calculate(order)

        values = order.participant(:dispatchable).load_curve.
          instance_variable_get(:@values).compact

        expect(values).to have(Merit::POINTS).members
      end

      it 'raises an error if using a chunk size of nil' do
        expect { QuantizingCalculator.new(nil) }.
          to raise_error(InvalidChunkSize)
      end

      it 'raises an error if using a chunk size of 1' do
        expect { QuantizingCalculator.new(1) }.
          to raise_error(InvalidChunkSize)
      end
    end # with QuantizingCalculator

  end # Calculator
end # Merit
