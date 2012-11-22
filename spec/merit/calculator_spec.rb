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

    before { Calculator.new(order).calculate! }

    # ------------------------------------------------------------------------

    it 'sets the load profile values of the first producer' do
      load_value = order.participant(:dispatchable).load_curve.get(0)

      expect(load_value).to_not be_nil
      expect(load_value).to be_within(0.1e-4).of(0.00597)
    end

    it 'sets the load profile values of the second producer' do
      load_value = order.participant(:volatile).load_curve.get(0)

      expect(load_value).to_not be_nil
      expect(load_value).to be_within(0.1e-4).of(0.095)
    end

    it 'sets the load profile values of the third producer' do
      load_value = order.participant(:volatile_two).load_curve.get(0)

      expect(load_value).to_not be_nil
      expect(load_value).to be_within(0.1e-4).of(0.00018)
    end

  end # Calculator
end # Merit
