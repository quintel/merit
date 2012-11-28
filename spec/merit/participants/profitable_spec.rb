require 'spec_helper'

module Merit

  describe Producer do

    let(:producer) do
      MustRunProducer.new(
        key:                       :coal,
        load_profile_key:          :industry_chp,
        effective_output_capacity: 1,
        marginal_costs:            2,
        availability:              0.95,
        number_of_units:           2,
        full_load_hours:           4
       )
    end

    describe '#revenue' do
      it 'should return the correct number' do
        order.stub(:price_curve) { LoadCurve.new(Array.new(8760,1)) }

        producer.order = Order.new
        expect(producer.revenue).to be_within(0.1).of(1 * 2 * 4.0)
      end
    end

  end # describe Producer

end # module Merit
