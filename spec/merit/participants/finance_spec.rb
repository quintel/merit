# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe Finance do
    # Who needs to be tested? --> ONLY the flex stuff, storage!!


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

    let(:curve) do
      day = [
        0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
        0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1
      ].map(&:to_f)

      Merit::Curve.new(day * 365)
    end

    # Add for flex!
    let(:order) { Order.new }

    before do
      allow(order).to receive(:price_curve)
        .and_return(Curve.new(Array.new(8760, 0.05)))

      producer.order = order

    end

    describe '#revenue' do
      context 'when the producer has 0 units' do
        it 'returns zero' do
          allow(producer).to receive(:number_of_units).and_return(0)
          expect(producer.revenue).to be(0.0)
        end
      end

      # TODO: no users, convert test to flex!
      # context 'when the user has 0 consumption' do
      #   it 'returns zero' do
      #     expect(user_total_consumption.revenue).to be(0.0)
      #   end
      # end

      context 'whith > 0 number of units and > 0 consumption' do
        it 'the producer returns the correct number' do
          expect(producer.revenue).to eq((2880.0 * 0.05) * Merit::POINTS)
        end

        # TODO: no users, convert test to flex!
        # it 'the user returns the correct number' do
        #   expect(user.revenue).to eq((0.5 * 0.05) * Merit::POINTS)
        # end
      end
    end

    describe '#revenue_curve' do
      it 'returns a Curve' do
        expect(producer.revenue_curve).to be_a(Curve)
      end

      it 'the producer has a correct revenue for the first hour' do
        expect(producer.revenue_curve.to_a.first).to eq(2880.0 * 0.05)
      end

      # TODO: no users, convert test to flex!
      # it 'the user has a correct fuel cost for the hours' do
      #   expect(user.revenue_curve.to_a.first(2)).to eq([0, 0.05])
      # end
    end
  end
end
