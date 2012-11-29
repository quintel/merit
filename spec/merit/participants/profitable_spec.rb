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

    let(:order) { Order.new }

    describe '#revenue' do
      it 'should return the correct number' do
        order.stub(:price_curve) { LoadCurve.new(Array.new(8760,1)) }

        producer.order = order
        expect(producer.revenue).to be_within(0.1).of(1 * 2 * 4.0)
      end
    end

    describe '#revenue_curve' do
      it 'should return a LoadCurve' do
        order.stub(:price_curve) { LoadCurve.new(Array.new(8760,1)) }

        producer.order = order
        expect(producer.revenue_curve).to be_a(LoadCurve)
        expect(producer.revenue_curve.to_a.first).to \
          be_within(0.01).of(8 / 8760.0)
      end
    end

  end # describe Producer

end # module Merit
