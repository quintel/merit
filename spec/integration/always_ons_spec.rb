# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Naming/VariableNumber
#
# Tests the `compute_always_ons` part of calculator, including that demands are satisfied and
# excesses assigned to flexible technologies.
#
# Each test assumes a static demand of 10 from a user, and two flexible technologies which will each
# consume a further 10. Tests are performed by varying the amount of hourly production from an
# always-on using the `ao_production` let variable.
RSpec.describe 'Calculation of always ons and flex' do
  let(:order) do
    Merit::Order.new.tap do |order|
      # Static demand of 10.
      order.add(FactoryBot.build(:user_with_curve))

      order.add(FactoryBot.build(:always_on, output_capacity_per_unit: ao_production.to_f))

      # Each consumes up to 10.
      order.add(flex_1)
      order.add(flex_2)
    end
  end

  let(:flex_1) do
    FactoryBot.build(
      :flex,
      marginal_costs: 10.0,
      input_capacity_per_unit: 10.0,
      output_capacity_per_unit: 10.0
    )
  end

  let(:flex_2) do
    FactoryBot.build(
      :flex,
      marginal_costs: flex_2_price.to_f,
      input_capacity_per_unit: 10.0,
      output_capacity_per_unit: 10.0
    )
  end

  let(:flex_2_price) { 5 }

  context 'when there is a demand of 10, and 10 always-on production' do
    let(:ao_production) { 10 }

    before { order.calculate }

    it 'assigns no excess to flex 1' do
      expect(flex_1.load_at(0)).to eq(0)
    end

    it 'assigns no excess to flex 2' do
      expect(flex_2.load_at(0)).to eq(0)
    end
  end

  context 'when there is a demand of 10, and 20 always-on production' do
    let(:ao_production) { 20.0 }

    before { order.calculate }

    it 'assigns 10 excess to flex 1' do
      expect(flex_1.load_at(0)).to eq(-10)
    end

    it 'assigns no excess to flex 2' do
      expect(flex_2.load_at(0)).to eq(0)
    end
  end

  context 'when there is demand of 10, 50 always-on production, and flex price is zero' do
    # When the flex technology price is zero, we don't assign any energy to them. This is because
    # we don't want to assign energy to an export interconnector when both the domestic and foreign
    # prices are zero.
    let(:ao_production) { 50.0 }

    let(:flex_1) do
      FactoryBot.build(
        :flex,
        marginal_costs: 0.0,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 10.0
      )
    end

    let(:flex_2) do
      FactoryBot.build(
        :flex,
        marginal_costs: flex_2_price.to_f,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 10.0
      )
    end

    before { order.calculate }

    it 'assigns no excess to flex 1' do
      expect(flex_1.load_at(0)).to eq(0)
    end

    it 'assigns 10 excess to flex 2' do
      expect(flex_2.load_at(0)).to eq(-10)
    end
  end

  context 'when there is demand of 10, 50 always-on production, and a black hole' do
    # Tests that a BlackHole will always consume regardless of price constraints.
    let(:ao_production) { 50.0 }

    let(:flex_1) do
      FactoryBot.build(
        :flex,
        marginal_costs: 0.0,
        input_capacity_per_unit: 10.0,
        output_capacity_per_unit: 10.0
      )
    end

    let(:flex_2) do
      FactoryBot.build(
        :black_hole,
        marginal_costs: 0.0,
        input_capacity_per_unit: 10.0
      )
    end

    before { order.calculate }

    it 'assigns no excess to flex 1' do
      expect(flex_1.load_at(0)).to eq(0)
    end

    it 'assigns 10 excess to the black hole' do
      expect(flex_2.load_at(0)).to eq(-10)
    end
  end

  context 'when there is a demand of 10, and 25 always-on production' do
    let(:ao_production) { 25.0 }

    context 'when flex 2 has a lower price than flex 1' do
      let(:flex_2_price) { 5 }

      before { order.calculate }

      it 'assigns 10 excess to flex 1' do
        expect(flex_1.load_at(0)).to eq(-10)
      end

      it 'assigns 5 excess to flex 2' do
        expect(flex_2.load_at(0)).to eq(-5)
      end
    end

    context 'when flex 2 has a higher price than flex 1' do
      let(:flex_2_price) { 15 }

      before { order.calculate }

      it 'assigns 5 excess to flex 1' do
        expect(flex_1.load_at(0)).to eq(-5)
      end

      it 'assigns 10 excess to flex 2' do
        expect(flex_2.load_at(0)).to eq(-10)
      end
    end
  end

  context 'when both flex have the same price' do
    let(:flex_2_price) { 10 }

    context 'when there is a demand of 10, and 20 always-on production' do
      let(:ao_production) { 20 }

      before { order.calculate }

      it 'assigns 5 excess to flex 1' do
        expect(flex_1.load_at(0)).to eq(-5)
      end

      it 'assigns 5 excess to flex 2' do
        expect(flex_2.load_at(0)).to eq(-5)
      end
    end

    context 'when there is a demand of 10, and 30 always-on production' do
      let(:ao_production) { 30 }

      before { order.calculate }

      it 'assigns 10 excess to flex 1' do
        expect(flex_1.load_at(0)).to eq(-10)
      end

      it 'assigns 10 excess to flex 2' do
        expect(flex_2.load_at(0)).to eq(-10)
      end
    end
  end

  context 'when there is a demand of 10, and 50 always-on production' do
    let(:ao_production) { 50.0 }

    before { order.calculate }

    it 'assigns 10 excess to flex 1' do
      expect(flex_1.load_at(0)).to eq(-10)
    end

    it 'assigns 10 excess to flex 2' do
      expect(flex_2.load_at(0)).to eq(-10)
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  context 'when there is 5 always-on production a dispatchable with capacity of 10' do
    let(:ao_production) { 5.0 }
    let(:dispatchable) { FactoryBot.build(:dispatchable, marginal_costs: 100.0) }

    before do
      order.add(dispatchable)
      order.calculate
    end

    it 'sets the dispatchable load to 5' do
      expect(dispatchable.load_at(0)).to eq(5)
    end
  end

  context 'when there is 50 always-on production a dispatchable with capacity of 10' do
    let(:ao_production) { 50.0 }
    let(:dispatchable) { FactoryBot.build(:dispatchable, marginal_costs: 100.0) }

    before do
      order.add(dispatchable)
      order.calculate
    end

    it 'sets the dispatchable load to 0' do
      expect(dispatchable.load_at(0)).to eq(0)
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
# rubocop:enable Naming/VariableNumber
