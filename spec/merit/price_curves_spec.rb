require 'spec_helper'

module Merit
  describe PriceCurves do
    let(:producer_attrs) {{
      output_capacity_per_unit:  1.0,
      number_of_units:           1,
      availability:              1.0,
      fixed_costs_per_unit:      1.0,
      fixed_om_costs_per_unit:   1.0
    }}

    let(:order) do
      order = Merit::Order.new

      order.add(producer_one)
      order.add(producer_two)
      order.add(producer_three)

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

      order
    end

    let(:producer_one) do
      DispatchableProducer.new(producer_attrs.merge(
        key: :one, marginal_costs: 10.0))
    end

    let(:producer_two) do
      DispatchableProducer.new(producer_attrs.merge(
        key: :two, marginal_costs: 20.0))
    end

    let(:producer_three) do
      DispatchableProducer.new(producer_attrs.merge(
        key: :three, marginal_costs: 30.0))
    end

    # --------------------------------------------------------------------------

    describe PriceCurves::FirstUnloaded do
      let(:curve) { PriceCurves::FirstUnloaded.new(order) }

      describe 'when no producers have load' do
        it 'sets the first producer to be price-setting' do
          expect(curve.producer_at(0)).to eq(producer_one)
        end

        it 'sets the price using the first producer' do
          expect(curve.get(0)).to eq(10.0)
        end
      end

      describe 'when one producer is loaded' do
        it 'sets the first unloaded producer to be price-setting' do
          expect(curve.producer_at(1)).to eq(producer_two)
        end

        it 'sets the price using the first unloaded producer' do
          expect(curve.get(1)).to eq(20.0)
        end
      end

      describe 'when a cost-function producer is partially-loaded' do
        let(:producer_one) do
          DispatchableProducer.new(producer_attrs.merge(
            key: :one, marginal_costs: 10.0, cost_spread: 0.5,
            number_of_units: 2))
        end

        it 'sets the first unloaded producer to be price-setting' do
          expect(curve.producer_at(1)).to eq(producer_one)
        end

        it 'sets the price using the first unloaded producer' do
          expect(curve.get(1)).to eq(10.0)
        end
      end

      describe 'when all producers are loaded' do
        it 'sets no producer to be price-setting' do
          expect(curve.producer_at(2)).to be_nil
        end

        it 'sets the price using a fallback' do
          expect(curve.get(2)).to eq(30.0 * 7.22)
        end
      end
    end # FirstUnloaded

    describe PriceCurves::LastLoaded do
      let(:curve) { PriceCurves::LastLoaded.new(order) }

      describe 'when no producers have load' do
        it 'sets the first producer to be price-setting' do
          expect(curve.producer_at(0)).to eq(producer_one)
        end

        it 'sets the price using the first producer' do
          expect(curve.get(0)).to eq(10.0)
        end
      end

      describe 'when one producer is loaded' do
        it 'sets the last loaded producer to be price-setting' do
          expect(curve.producer_at(1)).to eq(producer_one)
        end

        it 'sets the price using the last loaded producer' do
          expect(curve.get(1)).to eq(10.0)
        end
      end

      describe 'when a cost-function producer is partially-loaded' do
        let(:producer_one) do
          DispatchableProducer.new(producer_attrs.merge(
            key: :one, marginal_costs: 10.0, cost_spread: 0.5,
            number_of_units: 2))
        end

        it 'sets the cost-function producer to be price-setting' do
          expect(curve.producer_at(1)).to eq(producer_one)
        end

        it 'sets the price using the last-loaded cost-function step' do
          expect(curve.get(1)).to eq(7.5)
        end
      end

      describe 'when all producers are loaded' do
        it 'sets the last producer to be price-setting' do
          expect(curve.producer_at(2)).to eq(producer_three)
        end

        it 'sets the price using the last producer' do
          expect(curve.get(2)).to eq(30.0)
        end
      end
    end # LastLoaded
  end # PriceCurves
end # Merit
