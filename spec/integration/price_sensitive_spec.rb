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
  let(:ps_2_price) { 15 }

  let(:ps_1) do
    Merit::User::PriceSensitive.new(user_1, to_cost_strategy(ps_1_price))
  end

  let(:ps_2) do
    Merit::User::PriceSensitive.new(user_2, to_cost_strategy(ps_2_price))
  end

  let(:order) do
    Merit::Order.new.tap do |order|
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

      pending 'sets no demand on the first user' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      pending 'sets demand of the second user to 4' do
        expect(ps_2.load_at(0)).to eq(4)
      end
    end

    context 'when both always-ons provide 2 and the second price-sensitive ' \
            'has a higher price threshold in frame 1' do
      let(:capacity_1) { 2 }
      let(:capacity_2) { 2 }

      let(:ps_2_price) { [11, 20] }

      before { order.calculate }

      pending 'sets demand of the first user to 4 in frame 0' do
        expect(ps_1.load_at(0)).to eq(0)
      end

      pending 'sets no demand on the second user in frame 0' do
        expect(ps_2.load_at(0)).to eq(4)
      end

      pending 'sets no demand on the first user in frame 1' do
        expect(ps_1.load_at(1)).to eq(0)
      end

      pending 'sets demand of the second user to 4 in frame 1' do
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

      it 'sets no demand demand on the second user' do
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

      it 'sets no demand demand on the second user' do
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

      it 'sets no demand demand on the second user' do
        expect(ps_2.load_at(0)).to eq(0)
      end

      it 'sets load on the dispatchable to 2' do
        expect(di.load_at(0)).to eq(2)
      end
    end
  end
end
