require 'spec_helper'

module Merit
  describe Calculator do
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
        key: :dispatchable,
        marginal_costs:            13.999791,
        effective_output_capacity: 0.1,
        number_of_units:           1,
        availability:              0.89
      )
    end

    context 'with an excess of demand' do
      before { Calculator.new(order).calculate! }

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

      before { Calculator.new(order).calculate! }

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

  end # Calculator
end # Merit
