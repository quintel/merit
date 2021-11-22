# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers

RSpec.shared_examples 'a last-loaded price curve' do
  describe 'when no producers have load' do
    it 'sets surplus to be price-setting' do
      expect(curve.participant_at(0)).to eq(:surplus)
    end

    it 'sets the price to 0' do
      expect(curve.get(0)).to eq(0)
    end
  end

  describe 'when one producer is loaded' do
    it 'sets the last loaded producer to be price-setting' do
      expect(curve.participant_at(1)).to eq(producer_one)
    end

    it 'sets the price using the last loaded producer' do
      expect(curve.get(1)).to eq(10.0)
    end
  end

  describe 'when the second producer has negative load' do
    it 'sets the first producer to be price-setting' do
      expect(curve.participant_at(3)).to eq(producer_one)
    end

    it 'sets the price using the first producer' do
      expect(curve.get(3)).to eq(10.0)
    end
  end

  describe 'when a cost-function producer is partially-loaded' do
    let(:producer_one) do
      Merit::DispatchableProducer.new(participant_attrs.merge(
        key: :one, marginal_costs: 10.0, cost_spread: 0.5,
        number_of_units: 2
      ))
    end

    it 'sets the cost-function producer to be price-setting' do
      expect(curve.participant_at(1)).to eq(producer_one)
    end

    it 'sets the price using the last-loaded cost-function step' do
      expect(curve.get(1)).to eq(7.5)
    end
  end

  describe 'when all producers are loaded' do
    it 'sets the last producer to be price-setting' do
      expect(curve.participant_at(2)).to eq(producer_three)
    end

    it 'sets the price using the last producer' do
      expect(curve.get(2)).to eq(30.0)
    end
  end
end

describe Merit::PriceCurve do
  def participant_attrs
    {
      output_capacity_per_unit: 1.0,
      number_of_units: 1,
      availability: 1.0,
      fixed_costs_per_unit: 1.0,
      fixed_om_costs_per_unit: 1.0
    }
  end

  let(:order) do
    order = Merit::Order.new

    order.add(producer_one)
    order.add(producer_two)
    order.add(producer_three)

    order
  end

  let(:producer_one) do
    Merit::DispatchableProducer.new(participant_attrs.merge(
      key: :one, marginal_costs: 10.0
    ))
  end

  let(:producer_two) do
    Merit::DispatchableProducer.new(participant_attrs.merge(
      key: :two, marginal_costs: 20.0
    ))
  end

  let(:producer_three) do
    Merit::DispatchableProducer.new(participant_attrs.merge(
      key: :three, marginal_costs: 30.0
    ))
  end

  before do
    # Three points:
    #
    # 0 - No load anywhere.
    # 1 - Load on the first producer, but not the second and third.
    # 2 - Load on all three producers.

    producer_one.load_curve.set(0, 0.0)
    producer_two.load_curve.set(0, 0.0)
    producer_three.load_curve.set(0, 0.0)

    producer_one.load_curve.set(1, 0.5)
    producer_two.load_curve.set(1, 0.0)
    producer_three.load_curve.set(1, 0.0)

    producer_one.load_curve.set(2, 1.0)
    producer_two.load_curve.set(2, 1.0)
    producer_three.load_curve.set(2, 0.5)

    producer_one.load_curve.set(3, 1.0)
    producer_two.load_curve.set(3, -1.0)
    producer_three.load_curve.set(3, 0.0)
  end

  context 'with no price-sensitive consumers' do
    let(:curve) { described_class.new(order) }

    include_examples 'a last-loaded price curve'
  end

  context 'with dispatchables added out-of-order' do
    let(:order) do
      order = Merit::Order.new

      order.add(producer_three)
      order.add(producer_two)
      order.add(producer_one)

      order
    end

    let(:curve) { described_class.new(order) }

    include_examples 'a last-loaded price curve'
  end

  context 'with two price-sensitive consumers' do
    let(:ps_one) do
      Merit::Flex::Base.new(
        key: :ps_one,
        availability: 1.0,
        input_capacity_per_unit: 1.0,
        marginal_costs: 15.0,
        number_of_units: 1.0,
        output_capacity_per_unit: 0.0
      )
    end

    let(:ps_two) do
      Merit::Flex::Base.new(
        key: :ps_two,
        availability: 1.0,
        input_capacity_per_unit: 1.0,
        marginal_costs: 5.0,
        number_of_units: 1.0,
        output_capacity_per_unit: 0.0
      )
    end

    let(:order) do
      order = super()

      order.participants.add(ps_one)
      order.participants.add(ps_two)

      order
    end

    let(:curve) { described_class.new(order) }

    include_examples 'a last-loaded price curve'

    # 2021 flex improvement project: Case 2a
    describe 'when a price-sensitive is partially-loaded' do
      # This example tests when one price-sensitive has received energy from an always-on.
      before do
        ps_one.assign_excess(10, 0.5)
      end

      it 'sets the the price-sensitive is price-setting' do
        expect(curve.participant_at(10)).to eq(ps_one)
      end

      it 'sets the price equal to the price-sensitive' do
        expect(curve.get(10)).to eq(15.0)
      end
    end

    describe 'when a price-sensitive is discharging' do
      # Price-sensitives only set the price when charging. If they are price-setting when
      # discharging then they'll be checked with other dispatchables.
      before do
        ps_one.set_load(10, 0.5)
      end

      it 'does not set the the price-sensitive to be price-setting' do
        expect(curve.participant_at(10)).not_to eq(ps_one)
      end
    end

    # 2021 flex improvement project: Case 2b
    describe 'when all price-sensitives are fully-loaded' do
      # This example tests when all price-sensitives have received energy from an always-on and
      # are fully-loaded.
      before do
        ps_one.assign_excess(10, 1.0)
        ps_two.assign_excess(10, 1.0)
      end

      it 'sets surplus to be price-setting' do
        expect(curve.participant_at(10)).to eq(:surplus)
      end

      it 'sets the price to 0' do
        expect(curve.get(10)).to eq(0)
      end
    end

    describe 'when all price-sensitives are fully-loaded, supplied by dispatchables' do
      # This example tests when all price-sensitives have received energy from an always-on and
      # are fully-loaded.
      before do
        ps_one.assign_excess(10, 1.0)
        ps_two.assign_excess(10, 1.0)
        producer_one.set_load(10, 1.0)
      end

      it 'sets the first loaded dispatchable to be price-setting' do
        expect(curve.participant_at(10)).to eq(producer_one)
      end

      it 'sets the price equal to the dispatchable' do
        expect(curve.get(10)).to eq(10.0)
      end
    end

    # 2021 flex improvement project: Case 3
    describe 'when a dispatchable is fully- and price-sensitive is partially-loaded' do
      # This tests when a single price-sensitive has received energy from a dispatchable.
      before do
        producer_one.load_curve.set(10, 1.0)
        ps_one.assign_excess(10, 0.5)
        ps_two.assign_excess(10, 0.0)
      end

      it 'sets the price-sensitive to be price-setting' do
        expect(curve.participant_at(10)).to eq(ps_one)
      end

      it 'sets the price equal to the price-sensitive' do
        expect(curve.get(10)).to eq(15.0)
      end
    end

    # 2021 flex improvement project: Case 3
    describe 'when a dispatchable is partially- and price-sensitive is fully-loaded' do
      before do
        producer_one.load_curve.set(10, 0.5)
        ps_one.assign_excess(10, 1.0)
        ps_two.assign_excess(10, 0.0)
      end

      it 'sets the producer to be price-setting' do
        expect(curve.participant_at(10)).to eq(producer_one)
      end

      it 'sets the price equal to the producer' do
        expect(curve.get(10)).to eq(10.0)
      end
    end

    # 2021 flex improvement project: Case 6
    describe 'when a dispatchable and price-sensitive are both fully loaded' do
      before do
        producer_one.load_curve.set(10, 1.0)
        ps_one.assign_excess(10, 1.0)
      end

      it 'sets the producer to be price-setting' do
        expect(curve.participant_at(10)).to eq(producer_one)
      end

      it 'sets the price equal to the producer' do
        expect(curve.get(10)).to eq(10.0)
      end
    end

    # 2021 flex improvement project: Case 4
    describe 'when all dispatchables and price-sensitives are fully-loaded' do
      before do
        producer_one.load_curve.set(10, 1.0)
        producer_two.load_curve.set(10, 1.0)
        producer_three.load_curve.set(10, 1.0)
        ps_one.assign_excess(10, 1.0)
        ps_two.assign_excess(10, 1.0)
      end

      it 'sets deficit to be price-setting' do
        expect(curve.participant_at(10)).to eq(:deficit)
      end

      it 'sets a fallback price' do
        expect(curve.get(10)).to eq(3000.0)
      end
    end

    describe 'with variable price-sensitive pricing' do
      let(:ps_one) do
        Merit::Flex::Base.new(
          key: :ps_one,
          availability: 1.0,
          input_capacity_per_unit: 1.0,
          cost_curve: [10.0, 20.0] * 4380,
          number_of_units: 1.0,
          output_capacity_per_unit: 0.0
        )
      end

      let(:ps_two) do
        Merit::Flex::Base.new(
          key: :ps_two,
          availability: 1.0,
          input_capacity_per_unit: 1.0,
          cost_curve: [20.0, 10.0] * 4380,
          number_of_units: 1.0,
          output_capacity_per_unit: 0.0
        )
      end

      let(:curve) { described_class.new(order) }

      before do
        # Part-load both dispatchables. This isn't realistic but allows us to test that they swap
        # position in each hour.
        ps_one.load_curve.set(0, -5.0)
        ps_one.load_curve.set(1, -5.0)

        ps_two.load_curve.set(0, -5.0)
        ps_two.load_curve.set(1, -5.0)
      end

      it 'sets the first price-sensitive to be price-setting when cheaper' do
        expect(curve.participant_at(0)).to eq(ps_one)
      end

      it 'sets the second price-sensitive to be price-setting when cheaper' do
        expect(curve.participant_at(1)).to eq(ps_two)
      end
    end
  end

  describe 'with variable dispatchable pricing' do
    let(:producer_one) do
      Merit::DispatchableProducer.new(participant_attrs.merge(
        key: :one, cost_curve: [20.0, 10.0] * 4380
      ))
    end

    let(:producer_two) do
      Merit::DispatchableProducer.new(participant_attrs.merge(
        key: :two, cost_curve: [10.0, 20.0] * 4380
      ))
    end

    let(:curve) { described_class.new(order) }

    before do
      # Part-load both dispatchables. This isn't realistic but allows us to test that they swap
      # position in each hour.
      producer_one.load_curve.set(0, 5.0)
      producer_one.load_curve.set(1, 5.0)

      producer_two.load_curve.set(0, 5.0)
      producer_two.load_curve.set(1, 5.0)
    end

    it 'sets the first dispatchable to be price-setting when more expensive' do
      expect(curve.participant_at(0)).to eq(producer_one)
    end

    it 'sets the second dispatchable to be price-setting when more expensive' do
      expect(curve.participant_at(1)).to eq(producer_two)
    end
  end
end

# rubocop:enable RSpec/MultipleMemoizedHelpers
