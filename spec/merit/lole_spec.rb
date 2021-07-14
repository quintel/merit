# frozen_string_literal: true

require 'spec_helper'

module Merit
  RSpec.describe LOLE do
    let(:merit_order) do
      Order.new.tap do |mo|
        mo.add(Merit::User.create(
          key: :one_point_zero,
          load_profile: Curve.new([1.0, 1.0, 1.0, 1.0]),
          total_consumption: 1.0
        ))
      end
    end

    let(:expectation) do
      described_class
        .new(merit_order)
        .expectation(Curve.new(demand_curve), capacity, excludes)
    end

    let(:excludes) { [] }

    context 'with demand [2.0, 1.0, 2.0, 1.5]' do
      let(:demand_curve) { [2.0, 1.0, 2.0, 1.5] }

      context 'with capacity 2.0' do
        let(:capacity) { 2.0 }

        it 'has expectation of zero' do
          expect(expectation).to eq(0)
        end
      end

      context 'with capacity 1.5' do
        let(:capacity) { 1.5 }

        it 'has expectation of 2' do
          expect(expectation).to eq(2)
        end
      end

      context 'with capacity 0.5' do
        let(:capacity) { 0.5 }

        it 'has expectation of 4' do
          expect(expectation).to eq(4)
        end
      end

      context 'when excluding producer of 1.0' do
        # Demand becomes [1.0, 0.0, 1.0, 0.5]
        let(:excludes) { [:one_point_zero] }

        context 'with capacity 2.0' do
          let(:capacity) { 2.0 }

          it 'has expectation of zero' do
            expect(expectation).to eq(0)
          end
        end

        context 'with capacity 1.5' do
          let(:capacity) { 1.5 }

          it 'has expectation of zero' do
            expect(expectation).to eq(0)
          end
        end

        context 'with capacity 0.5' do
          let(:capacity) { 0.5 }

          it 'has expectation of 2' do
            expect(expectation).to eq(2)
          end
        end
      end

      context 'with capacity 1.5 and excluding a non-existent producer' do
        let(:excludes) { [:invalid] }
        let(:capacity) { 1.5 }

        it 'does not raise an error' do
          expect { expectation }.not_to raise_error
        end

        it 'has expectation of 2' do
          expect(expectation).to eq(2)
        end
      end
    end
  end
end
