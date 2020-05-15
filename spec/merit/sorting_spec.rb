# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Sorting do
  let(:p1) { FactoryBot.build(:dispatchable, p1_attrs) }
  let(:p2) { FactoryBot.build(:dispatchable, p2_attrs) }

  let(:source) { [p1, p2] }

  describe '.by_sortable_cost' do
    let(:sorting) { described_class.by_sortable_cost([p1, p2]) }

    context 'with fixed-price members' do
      let(:p1_attrs) { { marginal_costs: 20.0 } }
      let(:p2_attrs) { { marginal_costs: 10.0 } }

      it 'returns a Sorting::Fixed' do
        expect(sorting).to be_a(Merit::Sorting::Fixed)
      end

      it 'sorts less expensive members first' do
        sorted = sorting.at_point(0)
        expect(sorted.index(p1)).to be > sorted.index(p2)
      end
    end

    context 'with variable-priced members' do
      let(:p1_attrs) { { cost_curve: [20.0] } }
      let(:p2_attrs) { { cost_curve: [10.0] } }

      it 'returns a Sorting::Variable' do
        expect(sorting).to be_a(Merit::Sorting::Variable)
      end

      it 'sorts less expensive members first' do
        sorted = sorting.at_point(0)
        expect(sorted.index(p1)).to be > sorted.index(p2)
      end
    end
  end

  describe '.by_sortable_cost_desc' do
    let(:sorting) { described_class.by_sortable_cost_desc(source) }

    context 'with fixed-price members' do
      let(:p1_attrs) { { marginal_costs: 20.0 } }
      let(:p2_attrs) { { marginal_costs: 10.0 } }

      it 'returns a Sorting::Fixed' do
        expect(sorting).to be_a(Merit::Sorting::Fixed)
      end

      it 'sorts less expensive members first' do
        sorted = sorting.at_point(0)
        expect(sorted.index(p1)).to be < sorted.index(p2)
      end
    end

    context 'with variable-priced members' do
      let(:p1_attrs) { { cost_curve: [20.0] } }
      let(:p2_attrs) { { cost_curve: [10.0] } }

      it 'returns a Sorting::Variable' do
        expect(sorting).to be_a(Merit::Sorting::Variable)
      end

      it 'sorts less expensive members first' do
        sorted = sorting.at_point(0)
        expect(sorted.index(p1)).to be < sorted.index(p2)
      end
    end
  end
end
