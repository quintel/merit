# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calculation of price-sensitive demands' do
  def to_cost_strategy(pricing)
    if pricing.is_a?(Numeric)
      Merit::CostStrategy::Constant.new(nil, pricing)
    elsif pricing.is_a?(Array)
      Merit::CostStrategy::FromCurve.new(
        nil,
        Merit::Curve.new(pricing * (Merit::POINTS / pricing.length))
      )
    else
      pricing
    end
  end

  let(:user_1) { FactoryBot.build(:user_with_curve) }
  let(:user_2) { FactoryBot.build(:user_with_curve) }

  let(:ps_1_price) { 15 }
  let(:ps_2_price) { 14 }

  let(:ps_1) do
    Merit::User::PriceSensitive.new(
      user_1,
      to_cost_strategy(ps_1_price),
      :a_group
    )
  end

  let(:ps_2) do
    Merit::User::PriceSensitive.new(
      user_2,
      to_cost_strategy(ps_2_price),
      :a_group
    )
  end

  let(:order) do
    Merit::Order.new.tap do |order|
      order.participants.flex_groups.define(
        Merit::Flex::Group.new(
          ps_1.group,
          Merit::Sorting.by_sortable_cost_desc
        )
      )

      order.add(ps_1)
      order.add(ps_2)
    end
  end

  # Supplied by always-ons
  # ----------------------

  context 'with two users and two always-ons' do
    let(:capacity_1) { 10 }
    let(:capacity_2) { 10 }

    let(:ao_1) do
      FactoryBot.build(:always_on, output_capacity_per_unit: capacity_1.to_f)
    end

    let(:ao_2) do
      FactoryBot.build(:always_on, output_capacity_per_unit: capacity_2.to_f)
    end

    before do
      order.add(ao_1)
      order.add(ao_2)
    end

    context 'when both always-ons provide 10' do
      before { order.calculate }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end

      it 'calculates the production in MJ' do
        expect(ps_1.production).to eq(10 * Merit::POINTS * Merit::MJ_IN_MWH)
      end

      it 'calculates the production in MWh' do
        expect(ps_1.production(:mwh)).to eq(10 * Merit::POINTS)
      end
    end

    context 'when both always-ons provide 50' do
      before { order.calculate }

      let(:capacity_1) { 50 }
      let(:capacity_2) { 50 }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end
    end

    context 'when both always-ons provide 2' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      before { order.calculate }

      it 'sets demand of the first user to 4' do
        expect(ps_1.load_at(0)).to eq(4)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'calculates the production of the first user' do
        expect(ps_1.production).to eq(4 * Merit::POINTS * Merit::MJ_IN_MWH)
      end

      it 'calculates the production of the second user to be zero' do
        expect(ps_2.production).to eq(0)
      end
    end

    context 'when both always-ons provide 2 and the second price-sensitive ' \
            'has a higher price threshold' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      let(:ps_2_price) { 20 }

      before { order.calculate }

      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets demand of the second user to 4' do
        expect(ps_2.load_at(0)).to eq(4)
      end
    end

    context 'when both always-ons provide 2 and the second price-sensitive ' \
            'has a higher price threshold in frame 1' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      let(:ps_2_price) { [11, 20] }

      before { order.calculate }

      it 'sets demand of the first user to 4 in frame 0' do
        expect(ps_1.load_at(0)).to eq(4)
      end

      it 'sets no demand on the second user in frame 0' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no demand on the first user in frame 1' do
        expect(ps_1.load_at(1)).to eq(0)
      end

      it 'sets demand of the second user to 4 in frame 1' do
        expect(ps_2.load_at(1)).to eq(4)
      end
    end

    context 'when the first always-on provides 2 and the second provides 10' do
      let(:capacity_1) { 2 }

      before { order.calculate }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 2' do
        expect(ps_2.load_at(0)).to eq(2)
      end
    end

    context 'when both always-ons provide nothing' do
      let(:capacity_1) { 0 }
      let(:capacity_2) { 0 }

      before { order.calculate }

      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end
    end
  end

  # Supplied by dispatchables
  # -------------------------

  context 'with two users and two dispatchables' do
    let(:di_1) { FactoryBot.build(:dispatchable) }
    let(:di_2) { FactoryBot.build(:dispatchable) }

    before do
      order.add(di_1)
      order.add(di_2)
    end

    context 'when both dispatchables are price-competitive' do
      before { order.calculate }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end

      it 'sets the load of the first dispatchable to 10' do
        expect(di_1.load_at(0)).to eq(10)
      end

      it 'sets the load of the second dispatchable to 10' do
        expect(di_2.load_at(0)).to eq(10)
      end
    end

    # Ensures dispatchable energy is split equally between price-sensitives when there's
    # insufficient to max both out.
    context 'when both price sensitives have the same price' do
      let(:di_1) { FactoryBot.build(:dispatchable, output_capacity_per_unit: 1.0) }
      let(:di_2) { FactoryBot.build(:dispatchable, output_capacity_per_unit: 1.0) }

      let(:ps_1_price) { 15 }
      let(:ps_2_price) { 15 }

      # A user with a price different to the two other price-sensitives.
      let(:ne_1) do
        Merit::User::PriceSensitive.new(
          FactoryBot.build(:user_with_curve),
          to_cost_strategy([14, 14, 16, 16]),
          :a_group
        )
      end

      before do
        order.add(ne_1)
        order.calculate
      end

      context 'when non-equal user has a lower price threshold' do
        it 'sets demand of the first user to 1' do
          expect(ps_1.load_at(0)).to eq(1)
        end

        it 'sets demand of the second user to 1' do
          expect(ps_2.load_at(0)).to eq(1)
        end

        it 'sets demand of the non-equal priced user to 0' do
          expect(ne_1.load_at(0)).to eq(0)
        end

        it 'sets the load of the first dispatchable to 1' do
          expect(di_1.load_at(0)).to eq(1)
        end

        it 'sets the load of the second dispatchable to 1' do
          expect(di_2.load_at(0)).to eq(1)
        end
      end

      # Asserts that the assignment loop terminates.
      context 'when there is a large surplus' do
        let(:di_1) { FactoryBot.build(:dispatchable, output_capacity_per_unit: 25.0) }

        it 'sets demand of the first user to 10' do
          expect(ps_1.load_at(0)).to eq(10)
        end

        it 'sets demand of the second user to 10' do
          expect(ps_2.load_at(0)).to eq(10)
        end

        it 'sets demand of the non-equal priced user to 6' do
          # Five from di_1, one from di_2
          expect(ne_1.load_at(0)).to eq(6)
        end
      end

      context 'when non-equal user has a higher price threshold' do
        it 'sets demand of the first user to 0' do
          expect(ps_1.load_at(2)).to eq(0)
        end

        it 'sets demand of the second user to 0' do
          expect(ps_2.load_at(2)).to eq(0)
        end

        it 'sets demand of the non-equal priced user to 2' do
          expect(ne_1.load_at(2)).to eq(2)
        end

        it 'sets the load of the first dispatchable to 1' do
          expect(di_1.load_at(2)).to eq(1)
        end

        it 'sets the load of the second dispatchable to 1' do
          expect(di_2.load_at(2)).to eq(1)
        end
      end
    end

    # In point=1 both users have a price of 5, whereas the dispatchables are
    # selling at 5.
    context 'when neither dispatchable is price-competitive' do
      before { order.calculate }

      let(:ps_1_price) { 5 }
      let(:ps_2_price) { 5 }

      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no load on the first dispatchable' do
        expect(di_1.load_at(0)).to eq(0)
      end

      it 'sets no load on the second dispatchable' do
        expect(di_2.load_at(0)).to eq(0)
      end
    end

    context 'when both dispatchables have the same price as the ' \
            'price-sensitives' do
      let(:ps_1_price) { 10 }
      let(:ps_2_price) { 10 }

      before { order.calculate }

      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no demand on the first dispatchable' do
        expect(di_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second dispatchable' do
        expect(di_2.load_at(0)).to eq(0)
      end
    end

    context 'when the first dispatchable provides only 5.0' do
      let(:di_1) do
        FactoryBot.build(:dispatchable, output_capacity_per_unit: 5.0)
      end

      before { order.calculate }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 5.0' do
        expect(ps_2.load_at(0)).to eq(5)
      end

      it 'sets the load of the first dispatchable to 5' do
        expect(di_1.load_at(0)).to eq(5)
      end

      it 'sets the load of the second dispatchable to 10' do
        expect(di_2.load_at(0)).to eq(10)
      end
    end

    context 'when the first dispatchable provides only 5.0 and the second ' \
            'price-sensitive has a higher price threshold' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      let(:di_1) do
        FactoryBot.build(:dispatchable, output_capacity_per_unit: 5.0)
      end

      let(:ps_2_price) { 20 }

      before { order.calculate }

      it 'sets demand of the first user to 5' do
        expect(ps_1.load_at(0)).to eq(5)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end

      it 'sets the load of the first dispatchable to 5' do
        expect(di_1.load_at(0)).to eq(5)
      end

      it 'sets the load of the second dispatchable to 10' do
        expect(di_2.load_at(0)).to eq(10)
      end
    end

    context 'when the first dispatchable provides only 5.0 and the second ' \
        'price-sensitive has a higher price threshold in frame 1' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      let(:di_1) do
        FactoryBot.build(:dispatchable, output_capacity_per_unit: 5.0)
      end

      let(:ps_2_price) { [11, 20] }

      before { order.calculate }

      it 'sets demand of the first user to 10 in frame 0' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 5 in frame 0' do
        expect(ps_2.load_at(0)).to eq(5)
      end

      it 'sets the load of the first dispatchable to 5 in frame 0' do
        expect(di_1.load_at(0)).to eq(5)
      end

      it 'sets the load of the second dispatchable to 10 in frame 0' do
        expect(di_2.load_at(0)).to eq(10)
      end

      it 'sets demand of the first user to 5 in frame 1' do
        expect(ps_1.load_at(1)).to eq(5)
      end

      it 'sets demand of the second user to 10 in frame 1' do
        expect(ps_2.load_at(1)).to eq(10)
      end

      it 'sets the load of the first dispatchable to 5 in frame 1' do
        expect(di_1.load_at(1)).to eq(5)
      end

      it 'sets the load of the second dispatchable to 10 in frame 1' do
        expect(di_2.load_at(1)).to eq(10)
      end
    end

    context 'when the first dispatchable provides only 5.0 and the ' \
            'second provides 0.0' do
      let(:di_1) do
        FactoryBot.build(:dispatchable, output_capacity_per_unit: 5.0)
      end

      let(:di_2) do
        FactoryBot.build(:dispatchable, output_capacity_per_unit: 0.0)
      end

      before { order.calculate }

      it 'sets demand of the first user to 5' do
        expect(ps_1.load_at(0)).to eq(5)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets the load of the first dispatchable to 5.0' do
        expect(di_1.load_at(0)).to eq(5)
      end

      it 'sets no load on the second dispatchable' do
        expect(di_2.load_at(0)).to eq(0)
      end
    end

    context 'with a non-sensitive user and everything is price competitive' do
      before do
        order.add(FactoryBot.build(:user_with_curve))
        order.calculate
      end

      it 'demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets the load of the first dispatchable to 10' do
        expect(di_1.load_at(0)).to eq(10)
      end

      it 'sets the load of the second dispatchable to 10' do
        expect(di_2.load_at(0)).to eq(10)
      end
    end

    context 'with a non-sensitive user which consumes everything' do
      before do
        order.add(
          FactoryBot.build(
            :user_with_curve,
            load_curve: Merit::Curve.new([1000.0] * Merit::POINTS)
          )
        )

        order.calculate
      end

      it 'demand no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets the load of the first dispatchable to 10' do
        expect(di_1.load_at(0)).to eq(10)
      end

      it 'sets the load of the second dispatchable to 10' do
        expect(di_2.load_at(0)).to eq(10)
      end
    end

    context 'with a non-sensitive user and neither dispatchable is price ' \
            'competitive' do
      before do
        order.add(FactoryBot.build(:user_with_curve))
        order.calculate
      end

      let(:ps_1_price) { 5 }
      let(:ps_2_price) { 5 }

      it 'demand no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets the load of the first dispatchable to 10' do
        expect(di_1.load_at(0)).to eq(10)
      end

      it 'sets no load on the second dispatchable' do
        expect(di_2.load_at(0)).to eq(0)
      end
    end
  end

  # Supplied by always-ons and dispatchables
  # ----------------------------------------

  describe 'with two users, one always-on, and one dispatchable' do
    let(:ao_capacity) { 10 }
    let(:di_capacity) { 10 }

    let(:ao) do
      FactoryBot.build(
        :always_on,
        output_capacity_per_unit: ao_capacity.to_f
      )
    end

    let(:di) do
      FactoryBot.build(
        :dispatchable,
        output_capacity_per_unit: di_capacity.to_f
      )
    end

    before do
      order.add(ao)
      order.add(di)
    end

    context 'when both producers provide 10 and are price-competitive' do
      before { order.calculate }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end

      it 'sets the load of the dispatchable to 10' do
        expect(di.load_at(0)).to eq(10)
      end
    end

    context 'when both producers provide 10 and the dispatchable is not ' \
            'price-competitive' do
      before { order.calculate }

      let(:ps_1_price) { 5 }
      let(:ps_2_price) { 5 }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no load on the dispatchable' do
        expect(di.load_at(0)).to eq(0)
      end
    end

    context 'when the always-on provides 5 and the dispatchable is ' \
            'price-competitive' do
      before { order.calculate }

      let(:ao_capacity) { 5 }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 5' do
        expect(ps_2.load_at(0)).to eq(5)
      end

      it 'sets the load of the dispatchable to 10' do
        expect(di.load_at(0)).to eq(10)
      end
    end

    context 'when the always-on provides 5 and the dispatchable is not ' \
            'price-competitive' do
      before { order.calculate }

      let(:ao_capacity) { 5 }
      let(:ps_1_price) { 5 }
      let(:ps_2_price) { 5 }

      it 'sets demand of the first user to 5' do
        expect(ps_1.load_at(0)).to eq(5)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no load on the dispatchable' do
        expect(di.load_at(0)).to eq(0)
      end
    end

    context 'when the always-on provides 15 and the dispatchable is ' \
            'price-competitive' do
      before { order.calculate }

      let(:ao_capacity) { 50 }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets demand of the second user to 10' do
        expect(ps_2.load_at(0)).to eq(10)
      end

      it 'sets no load on the dispatchable' do
        expect(di.load_at(0)).to eq(0)
      end
    end

    context 'when the always-on provides nothing and the dispatchable is ' \
            'price-competitive' do
      before { order.calculate }

      let(:ao_capacity) { 0 }

      it 'sets demand of the first user to 10' do
        expect(ps_1.load_at(0)).to eq(10)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets the load of the dispatchable to 10' do
        expect(di.load_at(0)).to eq(10)
      end
    end

    context 'when neither producer provides anything' do
      before { order.calculate }

      let(:ao_capacity) { 0 }
      let(:di_capacity) { 0 }

      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets no load on the dispatchable' do
        expect(di.load_at(0)).to eq(0)
      end
    end

    context 'when both producers provides 2' do
      before { order.calculate }

      let(:ao_capacity) { 2 }
      let(:di_capacity) { 2 }

      it 'sets demand on the first user to 4' do
        expect(ps_1.load_at(0)).to eq(4)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets load on the dispatchable to 2' do
        expect(di.load_at(0)).to eq(2)
      end
    end
  end

  # Supplied by flex
  # ----------------

  # The price-sensitives want 120 each, and flex has received 1.0 energy. As a Base flex it should
  # never discharge energy.
  context 'with two users and a Flex::Base with a load of -1' do
    let(:flex) { FactoryBot.build(:flex) }

    before do
      flex.assign_excess(0, 1.0)

      order.add(flex)
      order.calculate
    end

    context 'when calculating the first hour' do
      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'does not change the flex load' do
        expect(flex.load_at(0)).to eq(-1)
      end
    end

    # Assert that the flex may not discharge the energy later in the calculation.
    context 'when calculating the second hour' do
      it 'sets no demand on the first user' do
        expect(ps_1.load_at(1)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(1)).to eq(0)
      end

      it 'does has no load on the flex' do
        expect(flex.load_at(1)).to eq(0)
      end
    end
  end

  # The price-sensitives want 10 each and the storage has 1.0 stored. Assert that the storage may be
  # discharged to meet the needs of the first user, but not the second, while correctly setting the
  # new load on the technology.
  context 'with two users and a Flex::Storage with a load of -1' do
    let(:storage) { FactoryBot.build(:storage, volume_per_unit: 2.0) }

    before do
      storage.assign_excess(0, 1.0)

      order.add(storage)
      order.calculate
    end

    # Storage may not output in the same hour as inputting.
    context 'when calculating the first hour' do
      it 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'does not change the storage load' do
        expect(storage.load_at(0)).to eq(-1)
      end

      it 'does not subtract energy from the reserve' do
        expect(storage.reserve.at(0)).to eq(1)
      end
    end

    # Storage may discharge an hour after inputting.
    context 'when calculating the second hour' do
      it 'sets demand of 1 on the first user' do
        expect(ps_1.load_at(1)).to eq(1)
      end

      it 'sets no demand on the second user' do
        expect(ps_2.load_at(1)).to eq(0)
      end

      it 'sets the load of the storage technology to 1' do
        expect(storage.load_at(1)).to eq(1)
      end

      it 'subtracts energy from the reserve' do
        expect(storage.reserve.at(1)).to eq(0)
      end
    end
  end

  # The price-sensitives want at most 10 each and the storage has 25 stored. Assert that the storage
  # may be discharged to meet the needs of the users, while correctly setting the new load on the
  # technology.
  context 'with two low-capacity users and a Flex::Storage with a load of -25' do
    let(:storage) do
      FactoryBot.build(
        :storage,
        input_capacity_per_unit: 30.0,
        output_capacity_per_unit: 30.0,
        volume_per_unit: 30.0
      )
    end

    before do
      storage.assign_excess(0, 25.0)
      order.add(storage)
    end

    context 'when calculating the second hour' do
      before { order.calculate }

      it 'sets demand of 10 on the first user' do
        expect(ps_1.load_at(1)).to eq(10)
      end

      it 'sets demand of 10 on the second user' do
        expect(ps_2.load_at(1)).to eq(10)
      end

      it 'sets the load of the storage technology to 20' do
        expect(storage.load_at(1)).to eq(20)
      end

      it 'has 5 remaining in the reserve' do
        expect(storage.reserve.at(1)).to eq(5)
      end
    end

    # Remove 10 energy from storage at the beginning of the second hour to simulate energy being
    # used to meet demand, prior to calculating the price-sensitive users.
    context 'when calculating the second hour and the storage has already had 10 removed' do
      before do
        calculator = Merit::StepwiseCalculator.new.calculate(order)
        calculator.call(0)

        storage.set_load(1, 10)
        calculator.call(1)
      end

      it 'sets demand of 10 on the first user' do
        expect(ps_1.load_at(1)).to eq(10)
      end

      it 'sets demand of 5 on the second user' do
        expect(ps_2.load_at(1)).to eq(5)
      end

      it 'changes the storage load to reflect the used energy' do
        expect(storage.load_at(1)).to eq(25)
      end

      it 'has nothing remaining in the reserve' do
        expect(storage.reserve.at(1)).to eq(0)
      end
    end
  end
end
