# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Flex::VariableConsumer do
  context 'with 10.0 output capacity' do
    let(:consumer) do
      FactoryBot.build(
        :variable_consumer,
        input_capacity_per_unit: 10.0,
        number_of_units: 1,
        availability: [1.0] * 8760
      )
    end

    it 'has unused capacity of 10 in hour 0' do
      expect(consumer.unused_input_capacity_at(0)).to eq(10)
    end

    it 'has unused capacity of 10 in hour 1' do
      expect(consumer.unused_input_capacity_at(1)).to eq(10)
    end

    it 'has no available output' do
      expect(consumer.max_load_at(0)).to eq(0)
    end
  end

  context 'with 10.0 output capacity and availability [1.0, 0.5, 0.25, 0.0]' do
    let(:consumer) do
      FactoryBot.build(
        :variable_consumer,
        input_capacity_per_unit: 10.0,
        number_of_units: 1,
        availability: [1.0, 0.5, 0.25, 0.0] * (8760 / 4)
      )
    end

    it 'has unused capacity of 10 in hour 0' do
      expect(consumer.unused_input_capacity_at(0)).to eq(10)
    end

    it 'has unused capacity of 5 in hour 1' do
      expect(consumer.unused_input_capacity_at(1)).to eq(5)
    end

    it 'has unused capacity of 2.5 in hour 2' do
      expect(consumer.unused_input_capacity_at(2)).to eq(2.5)
    end

    it 'has unused capacity of 0 in hour 3' do
      expect(consumer.unused_input_capacity_at(3)).to eq(0)
    end

    it 'has no available output' do
      expect(consumer.max_load_at(0)).to eq(0)
    end

    context 'with 5 consumption in hour 1' do
      before do
        consumer.assign_excess(1, 5)
      end

      it 'has unused capacity of 0' do
        expect(consumer.unused_input_capacity_at(1)).to eq(0)
      end

      it 'assigns no further excess' do
        expect(consumer.assign_excess(1, 1)).to eq(0)
      end
    end

    context 'with 2.5 consumption in hour 1' do
      before do
        consumer.assign_excess(1, 2.5)
      end

      it 'has unused capacity of 2.5' do
        expect(consumer.unused_input_capacity_at(1)).to eq(2.5)
      end

      it 'assigns 2.5 excess given 5' do
        expect(consumer.assign_excess(1, 5)).to eq(2.5)
      end

      it 'assigns 2.5 excess given 2.5' do
        expect(consumer.assign_excess(1, 2.5)).to eq(2.5)
      end

      it 'assigns 1.5 excess given 1.5' do
        expect(consumer.assign_excess(1, 1.5)).to eq(1.5)
      end
    end
  end

  context 'with 10.0 output capacity, 2 units, availability [1.0, 0.5]' do
    let(:consumer) do
      FactoryBot.build(
        :variable_consumer,
        input_capacity_per_unit: 10.0,
        number_of_units: 2,
        availability: [1.0, 0.5] * (8760 / 2)
      )
    end

    it 'has unused capacity of 20 in hour 0' do
      expect(consumer.unused_input_capacity_at(0)).to eq(20)
    end

    it 'has unused capacity of 10 in hour 1' do
      expect(consumer.unused_input_capacity_at(1)).to eq(10)
    end

    it 'has no available output' do
      expect(consumer.max_load_at(0)).to eq(0)
    end
  end
end
