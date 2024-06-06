# frozen_string_literal: true

require 'spec_helper'

# This spec checks the integration between participants that have a constrained
# production, and consumers that have a constrained demand. These components
# should be able to work together in order to simulate a direct connection
# between the two participants outside of the main market.

RSpec.describe 'Calculation of always ons and flex' do
  let(:order) do
    Merit::Order.new.tap do |order|
      order.add(producer)
      order.add(consumer)
    end
  end

  let(:producer) do
    build(
      :constrained_volatile_producer,
      output_capacity_per_unit: production,
      constraint: constraint
    )
  end

  let(:consumer) do
    build(
      :with_satisfied_demand,
      satisfied_demand_curve: satisfied_demand_curve,
      input_capacity_per_unit: consumption
    )
  end

  let(:production) { 1000 }
  let(:consumption) { 1000 }

  context 'with constraint being the same as satsfied demand' do
    let(:constraint) { ->(_, _) { 500 } }
    let(:satisfied_demand_curve) { Merit::Curve.new([-500] * Merit::POINTS) }

    before { order.calculate }

    it 'assigns the remaining energy to the consumer as well' do
      expect(consumer.load_at(0)).to eq(-1 * consumption)
    end

    it 'constrains the max_load on the producer, but not the load_curve' do
      expect(producer.load_curve[0] - producer.max_load_at(0)).to eq(500)
    end

    it 'the satisfied demand consumer is always price setting' do
      expect(consumer.price_setting?(0)).to be_truthy
    end

    context 'when there is an extra consumer with higher priority' do
      let(:order) do
        Merit::Order.new.tap do |order|
          order.add(producer)
          order.add(consumer)
          order.add(
            build(
              :flex,
              marginal_costs: 10.0,
              input_capacity_per_unit: 1000.0,
              output_capacity_per_unit: 0
            )
          )
        end
      end

      it 'assigns at least the satisfied demand to the satisfied-demand-consumer' do
        expect(consumer.load_at(0)).to be <= (-1 * consumption / 2.0)
      end

      it 'constrains the max_load on the producer, but not the load_curve' do
        expect(producer.load_curve[0] - producer.max_load_at(0)).to eq(500)
      end
    end

    context 'when there is an extra consumer that takes all excess energy' do
      let(:order) do
        Merit::Order.new.tap do |order|
          order.add(producer)
          order.add(consumer)
          order.add(
            build(
              :flex,
              marginal_costs: 100.0,
              input_capacity_per_unit: 1000.0,
              output_capacity_per_unit: 0
            )
          )
        end
      end

      it 'assigns the satisfied demand to the satisfied-demand-consumer' do
        expect(consumer.load_at(0)).to eq(-1 * consumption / 2.0)
      end

      it 'constrains the max_load on the producer, but not the load_curve' do
        expect(producer.load_curve[0] - producer.max_load_at(0)).to eq(500)
      end

      it 'the satisfied demand consumer is never price setting' do
        expect(consumer.price_setting?(0)).to be_falsey
      end
    end
  end

  context 'when constraint returns a negative value' do
    let(:constraint) { ->(_, _) { -500 } }
    let(:satisfied_demand_curve) { Merit::Curve.new([-500] * Merit::POINTS) }

    before { order.calculate }

    it 'assigns no extra energy to the consumer' do
      expect(consumer.load_at(0)).to eq(-500)
    end

    it 'constrains the max_load on the producer to 0' do
      expect(producer.max_load_at(0)).to eq(0)
    end
  end

  context 'when constraint returns a value larger than the original max_load' do
    let(:constraint) { ->(_, _) { 1500 } }
    let(:satisfied_demand_curve) { Merit::Curve.new([-500] * Merit::POINTS) }

    before { order.calculate }

    it 'assigns the remaining energy to the consumer as well' do
      expect(consumer.load_at(0)).to eq(-consumption)
    end

    it 'constrains the max_load on the producer to the orignal max_load' do
      expect(producer.max_load_at(0)).to eq(production)
    end
  end

  context 'when constraint is twice the amount of satisfied demand' do
    let(:constraint) { ->(_, _) { 500 } }
    let(:satisfied_demand_curve) { Merit::Curve.new([-250] * Merit::POINTS) }

    before { order.calculate }

    it 'has energy missing in the consumer' do
      expect(consumer.load_at(0)).to eq(-750)
    end

    it 'has energy missing in the system' do
      expect(consumer.load_at(0) + producer.load_curve[0]).not_to eq(0)
    end
  end

  context 'when satisfied demand is larger than the input_capacity of the consumer' do
    let(:constraint) { ->(_, _) { 1250 } }
    let(:satisfied_demand_curve) { Merit::Curve.new([-1250] * Merit::POINTS) }

    before { order.calculate }

    it 'constrains the consumers hourly load' do
      expect(consumer.load_at(0)).to eq(-consumption)
    end

    it 'constrains the consumers demand' do
      expect(consumer.production).to eq(consumption * 8760 * 3600)
    end

    it 'constrains the producer' do
      expect(producer.max_load_at(0)).to eq(production)
    end
  end
end
