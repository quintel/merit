# frozen_string_literal: true

require 'spec_helper'

# Users should be set up with "want" amounts of:
#
#   point 0 = 1.0
#   point 1 = 2.0
#
RSpec.shared_examples 'a price-sensitive User' do
  context 'when the "want" price is 10' do
    let(:price_curve) { [10, 10] }

    context 'when the "offer" price is 2.5 and amount is 0.5' do
      it 'accepts 0.5 energy when desiring 1' do
        expect(ps.barter_at(0, 0.5, 2.5)).to eq(0.5)
      end

      it 'accepts 0.5 energy when desiring 2' do
        expect(ps.barter_at(1, 0.5, 2.5)).to eq(0.5)
      end

      it 'calculates total production in MJ' do
        ps.barter_at(1, 0.5, 2.5)
        expect(ps.production).to eq(0.5 * Merit::MJ_IN_MWH)
      end

      it 'calculates total production in MWh' do
        ps.barter_at(1, 0.5, 2.5)
        expect(ps.production(:mwh)).to eq(0.5)
      end
    end

    context 'when the "offer" price is 2.5 and amount is 5' do
      it 'accepts 1 energy when desiring 1' do
        expect(ps.barter_at(0, 5.0, 2.5)).to eq(1)
      end

      it 'accepts 2.0 energy when desiring 2.0' do
        expect(ps.barter_at(1, 5.0, 2.5)).to eq(2)
      end
    end

    context 'when the "offer" price is 10 and amount is 1' do
      it 'accepts 1 energy when desiring 1' do
        expect(ps.barter_at(0, 1.0, 10.0)).to eq(1)
      end

      it 'accepts 1 energy when desiring 2' do
        expect(ps.barter_at(1, 1.0, 10.0)).to eq(1)
      end
    end

    context 'when the "offer" price is 11 and amount is 1' do
      it 'accepts no energy when desiring 1' do
        expect(ps.barter_at(0, 1.0, 11.0)).to eq(0)
      end

      it 'accepts no energy when desiring 2' do
        expect(ps.barter_at(1, 1.0, 11.0)).to eq(0)
      end
    end
  end

  context 'when offered an excess of 0.25' do
    let(:assign_excess) { ps.assign_excess(0, 0.25) }

    it 'sets the load to 0.25' do
      assign_excess
      expect(ps.load_at(0)).to eq(0.25)
    end

    it 'returns 0.25' do
      expect(assign_excess).to eq(0.25)
    end

    context 'when offered another 0.5' do
      before { assign_excess }

      let(:assign_excess_2) { ps.assign_excess(0, 0.5) }

      it 'sets the load to 0.75' do
        assign_excess_2
        expect(ps.load_at(0)).to eq(0.75)
      end

      it 'returns 0.5' do
        expect(assign_excess_2).to eq(0.5)
      end
    end

    context 'when offered another 10' do
      before { assign_excess }

      let(:assign_excess_2) { ps.assign_excess(0, 10.0) }

      it 'sets the load to 1' do
        assign_excess_2
        expect(ps.load_at(0)).to eq(1)
      end

      it 'returns 0.75' do
        expect(assign_excess_2).to eq(0.75)
      end
    end
  end
end

RSpec.describe Merit::User::PriceSensitive do
  let(:ps) do
    described_class.new(
      user,
      Merit::CostStrategy::FromCurve.new(nil, Merit::Curve.new(price_curve))
    )
  end

  let(:price_curve) { [5.0, 10.0] }

  describe 'wrapping a TotalConsumption' do
    let(:user) do
      Merit::User.create(
        key: :a,
        total_consumption: 1.0,
        load_profile: Merit::Curve.new([1.0, 2.0] * 4380)
      )
    end

    include_examples 'a price-sensitive User'
  end

  describe 'wrapping a WithCurve' do
    let(:user) do
      Merit::User.create(
        key: :a,
        load_curve: Merit::Curve.new([1.0, 2.0])
      )
    end

    include_examples 'a price-sensitive User'
  end

  describe 'wrapping a ConsumptionLoss' do
    let(:user) { Merit::User.create(key: :a, consumption_share: 0.5) }

    it 'raises an IllegalPriceSensitiveUser' do
      expect { ps }.to raise_error(Merit::IllegalPriceSensitiveUser)
    end
  end
end
