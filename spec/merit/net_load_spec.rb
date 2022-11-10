# frozen_string_literal: true

require 'spec_helper'

module Merit
  RSpec.describe NetLoad do
    let(:merit_order) { Order.new }
    let(:net_load) { described_class.new(merit_order).net_load }

    before do
      merit_order.add(Merit::MustRunProducer.new(
        key: :producer,
        load_profile: production,
        marginal_costs: 0,
        output_capacity_per_unit: 1,
        number_of_units: 1,
        full_load_hours: (1.0 / 3600.0)
      ))

      merit_order.add(Merit::User.create(
        key: :total_consumption,
        load_profile: consumption,
        total_consumption: 1
      ))
    end

    context 'empty curves' do
      let(:production)  { Curve.new([0, 0, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'has a value of 0' do
        expect(net_load[0]).to eq(0)
      end
    end

    context 'with excess consumption' do
      let(:production)  { Curve.new([0, 0, 0]) }
      let(:consumption) { Curve.new([1, 0, 0]) }

      it 'has a value of -1' do
        expect(net_load[0]).to eq(-1)
      end
    end

    context 'with excess production' do
      let(:production)  { Curve.new([1, 0, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'has a value of 1' do
        expect(net_load[0]).to eq(1)
      end
    end
  end
end
