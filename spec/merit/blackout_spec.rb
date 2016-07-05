require 'spec_helper'

module Merit
  RSpec.describe Blackout do
    let(:merit_order) { Order.new }
    let(:blackout) { Blackout.new(merit_order) }

    before do
      merit_order.add(Merit::MustRunProducer.new(
        key:                      :producer,
        load_profile:             production,
        marginal_costs:           0,
        output_capacity_per_unit: 1,
        number_of_units:          1,
        full_load_hours:          (1.0 / 3600.0)
      ))

      merit_order.add(Merit::User.create(
        key:               :total_consumption,
        load_profile:      consumption,
        total_consumption: 1
      ))
    end

    context "empty curves" do
      let(:production) {  Curve.new([0, 0, 0]) }
      let(:consumption) { Curve.new([0, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(blackout.number_of_hours).to eq(0)
      end
    end

    context "empty curves" do
      let(:production) {  Curve.new([0, 0, 0]) }
      let(:consumption) { Curve.new([1, 0, 0]) }

      it 'determines the excess of a chart' do
        expect(blackout.number_of_hours).to eq(1)
      end
    end
  end
end
