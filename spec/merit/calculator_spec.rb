require 'spec_helper'

module Merit
  describe 'Calculations' do
    let(:disp_1_attrs) {{
      key:                       :dispatchable,
      marginal_costs:            13.999791,
      output_capacity_per_unit:  0.1,
      number_of_units:           1,
      availability:              0.89,
      fixed_costs_per_unit:      222.9245208,
      fixed_om_costs_per_unit:   35.775
    }}

    let(:disp_2_attrs) {{
      key:                       :dispatchable_2,
      marginal_costs:            15.999791,
      output_capacity_per_unit:  0.005,
      number_of_units:           1,
      availability:              0.89,
      fixed_costs_per_unit:      222.9245208,
      fixed_om_costs_per_unit:   35.775
    }}

    let(:vol_1_attrs) {{
      key:                       :volatile,
      marginal_costs:            19.999791,
      load_profile:              LoadProfile.new([3.1709791984e-08]),
      output_capacity_per_unit:  0.1,
      availability:              0.95,
      number_of_units:           1,
      fixed_costs_per_unit:      222.9245208,
      fixed_om_costs_per_unit:   35.775,
      full_load_hours:           1000
    }}

    let(:vol_2_attrs) {{
      key:                       :volatile_two,
      marginal_costs:            21.21,
      load_profile:              LoadProfile.new([0.0]),
      output_capacity_per_unit:  0.1,
      availability:              0.95,
      number_of_units:           1,
      fixed_costs_per_unit:      222.9245208,
      fixed_om_costs_per_unit:   35.775,
      full_load_hours:           1000
    }}

    let(:user_attrs) {{
      key: :total_demand,
      total_consumption: 6.4e6,
      load_profile: LoadProfile.new([2.775668529550e-08])
    }}

    let(:order) do
      Order.new.tap do |order|
        order.add(dispatchable)
        order.add(dispatchable_two)

        order.add(volatile)
        order.add(volatile_two)

        order.add(user)
      end
    end

    let(:volatile)         { VolatileProducer.new(vol_1_attrs) }
    let(:volatile_two)     { VolatileProducer.new(vol_2_attrs) }
    let(:dispatchable)     { DispatchableProducer.new(disp_1_attrs) }
    let(:dispatchable_two) { DispatchableProducer.new(disp_2_attrs) }
    let(:user)             { User.create(user_attrs) }

    context 'with an excess of demand' do
      before { Calculator.new.calculate(order) }

      it 'sets the load profile values of the first producer' do
        load_value = dispatchable.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(dispatchable.max_load_at(0))
      end

      it 'sets the load profile values of the second producer' do
        load_value = volatile.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile.max_load_at(0))
      end

      it 'sets the load profile values of the third producer' do
        load_value = volatile_two.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile_two.max_load_at(0))
      end

      it 'assigns the price setting producer to be the last dispatchable' do
        expect(order.price_curve.producer_at(0)).to eq(dispatchable_two)
      end
    end

    context 'with an excess of always-on supply' do
      let(:vol_1_attrs) { super().merge(number_of_units: 200) }
      let(:vol_2_attrs) { vol_1_attrs.merge(key: :volatile_two) }

      before { order.calculate(Calculator.new) }

      it 'assigns the price setting producer to be next dispatchable' do
        expect(order.price_curve.producer_at(0)).to eql(dispatchable)
      end
    end

    context 'with an excess of supply' do
      let(:disp_1_attrs) { super().merge(number_of_units: 2) }
      before { order.calculate(Calculator.new) }

      it 'sets the load profile values of the first dispatchable' do
        load_value = dispatchable.load_curve.get(0)

        demand = order.participants.users.first.load_at(0)
        demand -= volatile.max_load_at(0)
        demand -= volatile_two.max_load_at(0)

        expect(load_value).to_not be_nil
        expect(load_value).to be_within(0.01).of(demand)
      end

      it 'sets the load profile values of the second dispatchable' do
        load_value = dispatchable.load_curve.get(0)

        demand = order.participants.users.first.load_at(0)
        demand -= volatile.max_load_at(0)
        demand -= volatile_two.max_load_at(0)

        expect(load_value).to_not be_nil
        expect(load_value).to be_within(0.01).of(demand)
      end

      it 'sets the load profile values of the second producer' do
        load_value = volatile.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile.max_load_at(0))
      end

      it 'sets the load profile values of the third producer' do
        load_value = volatile_two.load_curve.get(0)

        expect(load_value).to_not be_nil
        expect(load_value).to eql(volatile_two.max_load_at(0))
      end

      it 'assigns the price setting producer with the last-loaded dispatchable' do
        expect(order.price_curve.producer_at(0)).to eql(dispatchable)
      end

      context 'and the dispatchable is a cost-function producer' do
        let(:disp_1_attrs) do
          super().merge(cost_spread: 0.02, number_of_units: 2)
        end

        context 'with no remaining capacity' do
          it 'assigns the current dispatchable as price-setting' do
            expect(order.price_curve.producer_at(0)).to eql(dispatchable)
          end
        end # with no remaining capacity

        context 'with > 1 unit of remaining capacity' do
          let(:disp_1_attrs) do
            super().merge(cost_spread: 0.02, number_of_units: 3)
          end

          it 'assigns the current dispatchable as price-setting' do
            expect(order.price_curve.producer_at(0)).to eql(dispatchable)
          end
        end # with no remaining capacity
      end # and the dispatchable is a cost-function producer
    end

    context 'with a huge excess of supply' do
      before { volatile.instance_variable_set(:@number_of_units, 10**9) }
      before { order.calculate(Calculator.new) }

      it 'sets the load profile values of the first producer' do
        load_value = dispatchable.load_curve.get(0)

        expect(load_value).to eql 0.0
      end

      it 'sets the load profile values of the second producer' do
        load_value = volatile.load_curve.get(0)

        expect(load_value).to eql(volatile.max_load_at(0))
      end

      it 'sets the load profile values of the third producer' do
        load_value = volatile_two.load_curve.get(0)

        expect(load_value).to be_within(0.001).of(0.0)
      end

      it 'assigns the price setting producer to be the first producer' do
        expect(order.price_curve.producer_at(0)).to eql(dispatchable)
      end
    end

    describe 'with sub-zero demand' do
      let(:curve) { Merit::Curve.new([0, 0, -1, 3].map(&:to_f) * 6 * 365) }
      let(:cuser) { User.create(key: :with_curve, load_curve: curve) }

      let(:user_attrs) { super().merge(total_consumption: 0.0) }

      before { order.add(cuser) }

      it 'should return raise SubZeroDemand' do
        expect { Calculator.new.calculate(order) }
          .to raise_error(Merit::SubZeroDemand, /in point 2/)
      end
    end # with sub-zero demand

    context 'with highly-competitive dispatchers' do
      before { order.calculate(Calculator.new) }

      let(:order) do
        Order.new.tap do |order|
          order.add(dispatchable)
          order.add(dispatchable_two)
          order.add(user)
        end
      end

      let(:user_attrs) {{
        key: :curve_demand,
        load_curve: Curve.new([1.0] * Merit::POINTS)
      }}

      let(:disp_1_attrs) { super().merge(
        cost_spread: 0.4, marginal_costs: 20.0, availability: 1.0,
        output_capacity_per_unit: 0.1, number_of_units: 10
      ) }

      let(:disp_2_attrs) { super().merge(
        marginal_costs: 20.1, availability: 1.0,
        output_capacity_per_unit: 0.02, number_of_units: 1
      ) }

      it 'assigns all load to the first dispatchable' do
        # Dispatchable #1 has a lower mean price, even though it becomes more
        # expensive than #2 as we assign more load to it.
        expect(dispatchable.load_curve.get(0)).to eq(1.0)
      end

      it 'assigns no load to the second dispatchable' do
        expect(dispatchable_two.load_curve.get(0)).to be_zero
      end
    end # with highly-competitive dispatchers

    describe 'with a variable-marginal-cost producer' do
      let(:curve) do
        Curve.new([[12.0] * 24, [24.0] * 24, [12.0] * 120].flatten * 52)
      end

      let(:ic_attrs) {{
        key:                       :interconnect,
        cost_curve:                curve,
        output_capacity_per_unit:  1.0,
        availability:              1.0,
        fixed_costs_per_unit:      1.0,
        fixed_om_costs_per_unit:   1.0
      }}

      let(:ic) do
        SupplyInterconnect.new(ic_attrs)
      end

      # We need "dispatchable" to take all of the remaining demand when it is
      # competitive, so that none is assigned to the interconnector
      before { dispatchable.instance_variable_set(:@number_of_units, 30) }

      before { order.add(ic) }
      before { order.calculate(Calculator.new) }

      context 'when the producer is competitive' do
        let(:ic_attrs) { super().merge(output_capacity_per_unit: 0.2) }

        it 'should be active' do
          expect(ic.load_curve.get(0)).to_not be_zero
        end

        it 'is price-setting' do
          expect(order.price_curve.producer_at(0)).to eq(ic)
        end
      end # when the producer is competitive

      context 'when the producer is the final producer' do
        it 'should be active' do
          expect(ic.load_curve.get(0)).to_not be_zero
        end

        it 'is price-setting' do
          expect(order.price_curve.producer_at(0)).to eq(ic)
        end
      end # when the producer is competitive

      context 'when the producer is uncompetitive' do
        it 'should be inactive' do
          expect(ic.load_curve.get(24)).to be_zero
        end

        it 'is not price-setting' do
          expect(order.price_curve.producer_at(24)).to_not eq(ic)
        end
      end # when the producer is uncompetitive
    end # with a variable-marginal-cost producer

    describe 'with P2P storage' do
      let(:p2p_attrs) {{
        key: :p2p,
        volume_per_unit: 0.05,
        output_capacity_per_unit: 2.0,
        availability: 1.0,
        number_of_units: 1
      }}

      let(:user_attrs) {{
        key: :total_demand,
        total_consumption: 0.0,
        load_profile: LoadProfile.new([0.0])
      }}

      let(:p2p) { Flex::Storage.new(p2p_attrs) }

      let(:order) do
        Order.new.tap do |order|
          order.add(volatile)
          order.add(volatile_two)

          order.add(p2p)
          order.add(user)
        end
      end

      context 'with an excess of production' do
        before { order.calculate(Calculator.new) }

        it 'charges while there is excess and available volume' do
          # 0.01141552511424 is the excess
          expect(p2p.load_curve.to_a.take(4))
            .to eq([-0.01141552511424] * 4)
        end

        it 'charges when there is excess and partial volume remaining' do
          # Remaining volume is 0.0043
          expect(p2p.load_curve.get(4))
            .to be_within(1e-6).of(-0.0043379)
        end

        it 'does not charge when the reserve is full' do
          expect(p2p.load_curve.get(6)).to be_zero
        end

        context 'on two producers' do
          let(:vol_2_attrs) do
            super().merge(
              load_profile:             LoadProfile.new([3.1709791984e-08]),
              output_capacity_per_unit: 0.1,
            )
          end

          it "charges with both producers' output" do
            # 0.01141552511424 is the excess
            expect(p2p.load_curve.to_a.first)
              .to eq(-0.01141552511424 * 2)
          end
        end
      end # with an excess of production

      context 'when there is no excess' do
        let(:vol_1_attrs) do
          super().merge(load_profile: LoadProfile.new([0.0]))
        end

        let(:vol_2_attrs) do
          super().merge(load_profile: LoadProfile.new([0.0]))
        end

        before { p2p.reserve.add(0, 0.01) }
        before { order.calculate(Calculator.new) }

        it 'does not charge' do
          expect(p2p.load_curve.get(0)).to be_zero
        end

        it 'does not discharge' do
          expect(p2p.reserve.at(1)).to_not be_zero
          expect(p2p.reserve.at(1)).to eq(p2p.reserve.at(0))
        end
      end # when there is no excess

      context 'with a deficit, and the P2P contains energy' do
        let(:vol_1_attrs) do
          super().merge(load_profile: LoadProfile.new([0.0]))
        end

        let(:vol_2_attrs) do
          super().merge(load_profile: LoadProfile.new([0.0]))
        end

        let(:user_attrs) {{
          key: :total_demand,
          total_consumption: 6.4e6,
          load_profile: LoadProfile.new([0.0] + ([2.775668529550e-08] * 8759))
        }}

        let(:p2p_attrs) do
          super().merge(
            volume_per_unit: 1.0,
            output_capacity_per_unit: 0.15
          )
        end

        before { p2p.reserve.add(0, 0.4) }
        before { order.add(dispatchable) }
        before { order.calculate(Calculator.new) }

        it 'uses the P2P energy' do
          expect(p2p.load_curve.get(0)).to be_zero

          # Fulfil all demand
          expect(p2p.load_curve.get(1)).to eq(0.15)
          expect(p2p.load_curve.get(2)).to eq(0.15)

          # Partially empty.
          expect(p2p.load_curve.get(3)).to eq(0.1)

          # Completely empty.
          expect(p2p.load_curve.get(4)).to be_zero
        end

        it 'depletes the P2P reserve' do
          expect(p2p.reserve.at(0)).to eq(0.4)
          expect(p2p.reserve.at(1)).to eq(0.25)
          expect(p2p.reserve.at(2)).to eq(0.1)
          expect(p2p.reserve.at(3)).to be_zero
        end

        it 'reduces production from dispatchables' do
          reduced = dispatchable.load_curve.get(2)
          normal  = dispatchable.load_curve.get(9)

          expect(reduced).to be < normal
        end
      end # with a deficit, and the P2P contains energy
    end # with P2P storage

    describe 'with QuantizingCalculator' do
      # Set an excess of demand so that the dispatchable is running
      # all the time.
      let(:user_attrs) { super().merge(total_consumption: 6.4e7) }

      it 'should set a value for each load point' do
        QuantizingCalculator.new.calculate(order)

        values = order.participants[:dispatchable].load_curve.
          instance_variable_get(:@values).compact

        expect(values.length).to eq(Merit::POINTS)
      end

      it 'raises an error if using a chunk size of 1' do
        expect { QuantizingCalculator.new(1) }.
          to raise_error(InvalidChunkSize)
      end
    end # with QuantizingCalculator

    describe 'with AveragingCalculator' do
      it 'raises an error if using a chunk size of 1' do
        expect { AveragingCalculator.new(1) }.
          to raise_error(InvalidChunkSize)
      end

      describe 'with an excess of demand' do
        # Set an excess of demand so that the dispatchable is running
        # all the time.
        let(:user_attrs) { super().merge(total_consumption: 6.4e7) }

        it 'should set a value for each nth load point' do
          AveragingCalculator.new.calculate(order)

          values = order.participants[:dispatchable].load_curve.
            instance_variable_get(:@values).compact

          expect(values.length).to eq(Merit::POINTS / 8)
        end
      end

      describe 'with less demand than capacity' do
        let(:user_attrs) { super().merge(total_consumption: 1e6) }

        it "doesn't over-assign load" do
          # Explicitly tests assigning the "remaining" demand in
          # AveragingCalulator#compute_point
          expect {
            AveragingCalculator.new.calculate(order)
          }.to_not raise_error
        end
      end

      describe 'with no demand' do
        # Set zero demand so that each producers receives zero. This
        # explicitly tests the "break" in AveragingCalculator#compute_point
        let(:user_attrs) { super().merge(total_consumption: 0.0) }

        it "only assigns demand when some is present" do
          expect {
            AveragingCalculator.new.calculate(order)
          }.to_not raise_error
        end
      end
    end # with AveragingCalculator

    context 'when producer order is incorrect' do
      # Impossible with the current Order class, but serves as a regression
      # test.
      it 'raises an error' do
        allow(order.participants).to receive(:producers).and_return([
          volatile, dispatchable, volatile_two])

        expect { Calculator.new.calculate(order) }.
          to raise_error(IncorrectProducerOrder)
      end
    end

  end # Calculator
end # Merit
