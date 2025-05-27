# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe Finance::Base do
    let(:producer) do
      MustRunProducer.new(
        key: :coal,
        load_profile: LoadProfile.new([0.1]),
        output_capacity_per_unit: 1,
        marginal_costs: 2,
        availability: 0.95,
        number_of_units: 2,
        full_load_hours: 4,
        fixed_costs_per_unit: 30,
        fixed_om_costs_per_unit: 17
      )
    end

    let(:order) { Order.new }

    describe '#profitable' do
      it 'is :profitable if revenue > total_costs' do
        allow(producer).to receive(:revenue).and_return(1000)
        allow(producer).to receive(:total_costs).and_return(500)
        expect(producer.profitability).to be(:profitable)
      end

      it 'is :conditionally_profitable if OPEX = <revenue < total_costs' do
        allow(producer).to receive(:revenue).and_return(500)
        allow(producer).to receive(:total_costs).and_return(1000)
        allow(producer).to receive(:operating_costs).and_return(300)
        expect(producer.profitability).to be(:conditionally_profitable)
      end

      it 'is :unprofitable if revenue < OPEX' do
        allow(producer).to receive(:revenue).and_return(500)
        allow(producer).to receive(:total_costs).and_return(1000)
        allow(producer).to receive(:operating_costs).and_return(700)
        expect(producer.profitability).to be(:unprofitable)
      end
    end

    describe '#profit' do
      it 'calculates correctly' do
        allow(producer).to receive(:revenue).and_return(1000)
        allow(producer).to receive(:total_costs).and_return(500)
        expect(producer.profit).to be(500)
      end
    end

    describe '#revenue' do
      context 'when the producer has either 0 units or no capacity' do
        it 'returns zero when it has 0 units' do
          allow(producer).to receive(:number_of_units).and_return(0)
          expect(producer.revenue).to be(0.0)
        end

        it 'returns zero when capacity = 0' do
          allow(producer).to receive(:output_capacity_per_unit).and_return(0)
          expect(producer.revenue).to be(0.0)
        end
      end

      context 'when the producer has >0 number of units and >0 capacity' do
        it 'returns the correct number' do
          allow(order).to receive(:price_curve)
            .and_return(Curve.new(Array.new(8760, 0.05)))

          producer.order = order
          expect(producer.revenue).to eq((2880.0 * 0.05) * Merit::POINTS)
        end
      end
    end

    describe '#revenue_curve' do
      it 'returns a Curve' do
        allow(order).to receive(:price_curve)
          .and_return(Curve.new(Array.new(8760, 0.05)))

        producer.order = order

        expect(producer.revenue_curve).to be_a(Curve)
        expect(producer.revenue_curve.to_a.first).to eq(2880.0 * 0.05)
      end
    end

    describe '#total_costs' do
      it 'calculates correctly' do
        allow(producer).to receive(:fixed_costs).and_return(1000)
        allow(producer).to receive(:variable_costs).and_return(500)
        expect(producer.total_costs).to be(1500)
      end
    end

    describe '#variable_costs' do
      it 'calculates correctly' do
        allow(producer).to receive(:production).and_return(1000) # MWh
        expect(producer.variable_costs).to eql(2 * 1000)
      end
    end

    describe '#fixed_costs' do
      it 'calculates correctly' do
        expect(producer.fixed_costs).to eql(30 * 2)
      end
    end

    describe '#fixed_om_costs' do
      it 'calculates correctly' do
        expect(producer.fixed_om_costs).to eql(17 * 2)
      end
    end

    describe '#operating_costs' do
      it 'calculates correctly' do
        allow(producer).to receive(:variable_costs).and_return(17.4)
        expect(producer.operating_costs).to eql(17 * 2 + 17.4)
      end
    end

    describe '#profit_per_mwh_electricity' do
      before do
        @dispatchable = DispatchableProducer.new(
          key: :foo,
          marginal_costs: 50,
          output_capacity_per_unit: 1,
          number_of_units: 1,
          availability: 0.8,
          fixed_costs_per_unit: 100,
          fixed_om_costs_per_unit: 30
        )
        order.add(@dispatchable)
      end

      it 'calculates correctly' do
        allow(@dispatchable).to receive(:production).and_return(1)
        # marginal costs + fixed_costs_per_unit
        expect(@dispatchable.profit_per_mwh_electricity).to be(-150.0)
      end

      it 'returns nil if the production is 0' do
        allow(@dispatchable).to receive(:production).and_return(0)
        expect(@dispatchable.profit_per_mwh_electricity).to be_nil
      end
    end
  end
end
