# frozen_string_literal: true

require 'spec_helper'

describe Merit::Flex::CostBasedShareGroup do
  let(:equal_flex_one) do
    FactoryBot.build(:flex, input_capacity_per_unit: 3.0, marginal_costs: 1.0)
  end

  let(:equal_flex_two) do
    FactoryBot.build(:flex, input_capacity_per_unit: 1.0, marginal_costs: 1.0)
  end

  let(:nonequal_flex) do
    FactoryBot.build(:flex, input_capacity_per_unit: 1.0, marginal_costs: 2.0)
  end

  let(:group) do
    sorting = Merit::Sorting.by_sortable_cost

    described_class.new(:a, sorting).tap do |group|
      group.insert(equal_flex_one)
      group.insert(equal_flex_two)
      group.insert(nonequal_flex)
    end
  end

  context 'when all participants have no assigned load yet' do
    # All flex unloaded.
    context 'when assigning 0 energy' do
      let!(:assigned) { group.assign_excess(0, 0.0) }

      it 'returns 0' do
        expect(assigned).to eq(0)
      end

      it 'assigns nothing to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(0)
      end

      it 'assigns nothing to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(0)
      end

      it 'assigns nothing to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(0)
      end
    end

    # Equal flex fully loaded, non-equal flex unloaded.
    context 'when assigning 4 energy' do
      let!(:assigned) { group.assign_excess(0, 4.0) }

      it 'returns 4' do
        expect(assigned).to eq(4)
      end

      it 'assigns 3.0 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-3)
      end

      it 'assigns 1.0 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-1)
      end

      it 'assigns nothing to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(0)
      end
    end

    # Equal flex partially loaded, non-equal flex unloaded.
    context 'when assigning 2 energy' do
      before { group.assign_excess(0, 2.0) }

      it 'assigns 1.5 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-1.5)
      end

      it 'assigns 0.5 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-0.5)
      end

      it 'assigns nothing to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(0)
      end
    end

    # All equal flex loaded, non-equal partially loaded.
    context 'when assigning 4.5 energy' do
      before { group.assign_excess(0, 4.5) }

      it 'assigns 3.0 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-3.0)
      end

      it 'assigns 1.0 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-1.0)
      end

      it 'assigns 0.5 to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(-0.5)
      end
    end

    # All flex fully loaded.
    context 'when assigning 10 energy' do
      let!(:assigned) { group.assign_excess(0, 10.0) }

      it 'returns 5' do
        expect(assigned).to eq(5)
      end

      it 'assigns 3.0 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-3)
      end

      it 'assigns 1.0 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-1)
      end

      it 'assigns 1.0 to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(-1)
      end
    end
  end

  context 'when the first equal participant already has load of 1.0' do
    before { equal_flex_one.assign_excess(0, 1.0) }

    context 'when assigning 4 energy' do
      before { group.assign_excess(0, 4.0) }

      it 'assigns 2.0 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-1 + -2)
      end

      it 'assigns 1.0 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-1)
      end

      it 'assigns 1.0 to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(-1)
      end
    end

    # Assign fairly between equals based on their remaining capacity, not total capacity.
    context 'assigning 1.5 energy' do
      before { group.assign_excess(0, 1.5) }

      it 'assigns 1.0 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-1 + -1)
      end

      it 'assigns 0.5 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-0.5)
      end

      it 'assigns nothing to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(0)
      end
    end
  end

  context 'when equal and non-equal participants swap order in frame 1' do
    let(:nonequal_flex) do
      FactoryBot.build(:flex, output_capacity_per_unit: 1.0, cost_curve: [2.0, 0.5])
    end

    context 'when assigning 1 energy in frame 0' do
      before { group.assign_excess(0, 1.0) }

      it 'assigns 0.75 to equal flex one' do
        expect(equal_flex_one.load_at(0)).to eq(-0.75)
      end

      it 'assigns 0.25 to equal flex two' do
        expect(equal_flex_two.load_at(0)).to eq(-0.25)
      end

      it 'assigns nothing to the non-equal flex' do
        expect(nonequal_flex.load_at(0)).to eq(0)
      end
    end

    context 'when assigning 1 energy in frame 1' do
      before { group.assign_excess(1, 1.0) }

      it 'assigns nothing to equal flex one' do
        expect(equal_flex_one.load_at(1)).to eq(0)
      end

      it 'assigns nothing to equal flex two' do
        expect(equal_flex_two.load_at(1)).to eq(0)
      end

      it 'assigns 1.0 to the non-equal flex' do
        expect(nonequal_flex.load_at(1)).to eq(-1)
      end
    end
  end
end
