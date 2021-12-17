# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Flex::Collection do
  let(:collection) { described_class.new(Merit::Sorting.by_sortable_cost(techs)) }

  context 'when given a Sortable::Fixed' do
    let(:techs) do
      [
        FactoryBot.build(:flex, marginal_costs: 1),
        FactoryBot.build(:flex, marginal_costs: 2),
        FactoryBot.build(:flex, marginal_costs: 2)
      ]
    end

    it 'groups the given technologies' do
      expect(collection.at_point(0).length).to eq(2)
    end

    it 'groups the same-price technologies' do
      expect(collection.at_point(0)[1]).to be_a(Merit::Flex::Group)
    end

    it 'does not group unique-priced technologies' do
      expect(collection.at_point(0)[0]).to be_a(Merit::Flex::Base)
    end

    it 'returns the same object each time' do
      expect(collection.at_point(0).object_id).to eq(collection.at_point(1).object_id)
    end
  end

  context 'when given a Sortable::Variable' do
    let(:techs) do
      [
        FactoryBot.build(:flex, marginal_costs: 1),
        FactoryBot.build(:flex, marginal_costs: 2),
        FactoryBot.build(:flex, cost_curve: [1, 2])
      ]
    end

    it 'returns a different object for each point' do
      expect(collection.at_point(0).object_id).not_to eq(collection.at_point(1).object_id)
    end

    context 'when fetching techs for point 0' do
      it 'groups the given technologies' do
        expect(collection.at_point(0).length).to eq(2)
      end

      it 'groups the same-price technologies' do
        expect(collection.at_point(0)[0]).to be_a(Merit::Flex::Group)
      end

      it 'does not group unique-priced technologies' do
        expect(collection.at_point(0)[1]).to be_a(Merit::Flex::Base)
      end
    end

    context 'when fetching techs for point 1' do
      it 'groups the given technologies' do
        expect(collection.at_point(1).length).to eq(2)
      end

      it 'groups the same-price technologies' do
        expect(collection.at_point(1)[0]).to be_a(Merit::Flex::Base)
      end

      it 'does not group unique-priced technologies' do
        expect(collection.at_point(1)[1]).to be_a(Merit::Flex::Group)
      end
    end
  end
end
