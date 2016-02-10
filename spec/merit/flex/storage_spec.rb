require 'spec_helper'

module Merit
  describe Flex::Storage do
    let(:attrs) {{
      key: :p2p,
      number_of_units: 1,
      output_capacity_per_unit: 10.0,
      input_efficiency: 1.0,
      output_efficiency: 1.0,
      volume_per_unit: 10.0
    }}

    let(:storage) { Flex::Storage.new(attrs) }

    # --

    describe 'max_load_at' do
      context 'when empty' do
        it 'returns zero' do
          expect(storage.max_load_at(0)).to be_zero
        end
      end # when empty

      context 'with 1.0 stored' do
        before { storage.reserve.set(0, 1.0) }

        context 'and output capacity: 10.0' do
          it 'returns 1.0' do
            expect(storage.max_load_at(1)).to eq(1.0)
          end

          context 'and output_efficiency: 0.75' do
            let(:attrs) { super().merge(output_efficiency: 0.75) }

            it 'returns 0.75' do
              expect(storage.max_load_at(1)).to eq(0.75)
            end
          end
        end # and output capacity: 10.0

        context 'and output capacity: 0.5' do
          let(:attrs) { super().merge(output_capacity_per_unit: 0.5) }

          # We have to store 1.0x2 in order to store 1.0 (0.5 capacity is the
          # limiting factor for this tech).
          before { storage.assign_excess(1, 1.0) }

          it 'returns 0.5' do
            expect(storage.max_load_at(2)).to eq(0.5)
          end

          context 'and output_efficiency: 0.75' do
            let(:attrs) { super().merge(output_efficiency: 0.75) }

            it 'returns 0.5' do
              expect(storage.max_load_at(2)).to eq(0.5)
            end
          end
        end # and output capacity: 0.5

        context 'and input capacity: 0.25' do
          # Output is unaffected by input capacity
          let(:attrs) { super().merge(input_capacity_per_unit: 0.25) }

          it 'returns 1.0' do
            expect(storage.max_load_at(1)).to eq(1.0)
          end
        end # and output capacity: 10.0
      end # with 1.0 stored
    end # max_load_at

    # --

    describe 'assign_excess' do
      context 'storing 2.0' do
        context 'with nothing stored' do
          let(:store_load) { storage.assign_excess(0, 2.0) }

          it 'stores 2.0' do
            expect { store_load }
              .to change { storage.reserve.at(0) }.from(0.0).to(2.0)
          end

          it 'returns 2.0' do
            expect(store_load).to eq(2.0)
          end

          it 'sets a load of -2.0' do
            store_load
            expect(storage.load_curve.get(0)).to eq(-2.0)
          end

          it 'has production of 7200 MJ' do
            expect { store_load }
              .to change { storage.production }
              .from(0.0).to(2.0 * 3600)
          end
        end # with nothing stored

        context 'with 8.0 already stored' do
          before { storage.reserve.add(0, 8.0) }

          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 2.0' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(8.0).to(10.0)
          end

          it 'returns 2.0' do
            expect(storage.assign_excess(1, 2.0)).to eq(2.0)
          end

          it 'sets a load of -2.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-2.0)
          end

          it 'has production of 7200 MJ' do
            expect { store_load }
              .to change { storage.production }
              .from(0.0).to(2.0 * 3600)
          end
        end # with 8.0 already stored

        context 'with 9.0 already stored' do
          before { storage.reserve.add(0, 9.0) }

          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 1.0' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(9.0).to(10.0)
          end

          it 'returns 1.0' do
            expect(store_load).to eq(1.0)
          end

          it 'sets a load of -1.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-1.0)
          end

          it 'has production of 3600 MJ' do
            expect { store_load }
              .to change { storage.production }
              .from(0.0).to(3600)
          end
        end # with 9.0 already stored

        context 'with a volume_per_unit of 0.0' do
          let(:attrs) { super().merge(volume_per_unit: 0.0) }

          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'returns 0.0' do
            expect(store_load).to be_zero
          end

          it 'sets no load' do
            store_load
            expect(storage.load_curve.get(1)).to be_zero
          end
        end

        context 'with a capacity of 3.0, 2.0 already stored' do
          before { storage.assign_excess(1, 2.0) }

          let(:attrs) { super().merge(output_capacity_per_unit: 3.0) }
          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'returns 1.0' do
            expect(store_load).to eq(1.0)
          end

          it 'sets a load of -3.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-3.0)
          end
        end # with a capacity of 3.0, 2.0 already stored

        context 'with an availability of 0.1' do
          let(:attrs) { super().merge(availability: 0.1) }
          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 1.0' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(0.0).to(1.0)
          end

          it 'returns 1.0' do
            expect(store_load).to eq(1.0)
          end

          it 'sets a load of -1.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-1.0)
          end
        end

        context 'with 10.0 already stored' do
          before { storage.reserve.add(0, 10.0) }

          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores nothing' do
            expect { store_load }
              .to_not change { storage.reserve.at(1) }.from(10.0)
          end

          it 'returns zero' do
            expect(store_load).to be_zero
          end

          it 'sets no load' do
            store_load
            expect(storage.load_curve.get(1)).to be_zero
          end
        end # with 10.0 already stored

        context 'with an input efficiency of 0.75' do
          let(:attrs) { super().merge(input_efficiency: 0.75) }
          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 1.5' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(0.0).to(1.5)
          end

          it 'returns 2.0' do
            expect(store_load).to eq(2.0)
          end

          it 'sets a load of -2.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-2.0)
          end
        end # with an input efficiency of 0.75

        context 'with an input capacity of 0.5' do
          let(:attrs) { super().merge(input_capacity_per_unit: 0.5) }
          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 0.5' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(0.0).to(0.5)
          end

          it 'returns 0.5' do
            expect(store_load).to eq(0.5)
          end

          it 'sets a load of -0.5' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-0.5)
          end
        end # with an input capacity of 0.5

        context 'with an output capacity of 0.25 and no input capacity' do
          let(:attrs) { super().merge(output_capacity_per_unit: 0.25) }
          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 0.25' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(0.0).to(0.25)
          end

          it 'returns 0.25' do
            expect(store_load).to eq(0.25)
          end

          it 'sets a load of -0.25' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-0.25)
          end
        end # with an output capacity of 0.25 and no input capacity

        context 'with an input capacity of 0.5 and input efficiency of 0.75' do
          let(:attrs) do
            super().merge(
              input_capacity_per_unit: 0.5,
              input_efficiency: 0.75
            )
          end

          let(:store_load) { storage.assign_excess(1, 2.0) }

          it 'stores 0.375' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(0.0).to(0.375)
          end

          it 'returns 0.5' do
            expect(store_load).to eq(0.5)
          end

          it 'sets a load of -0.5' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-0.5)
          end
        end # with an input capacity of 0.5 and input efficiency of 0.75
      end # storing 2.0

      context 'storing -2.0' do
        let(:store_load) { storage.assign_excess(1, -2.0) }

        it 'returns 0.0' do
          expect(store_load).to be_zero
        end

        it 'sets no load' do
          store_load
          expect(storage.load_curve.get(1)).to be_zero
        end
      end

    end # store

    # --

    describe 'set_load' do
      before { storage.reserve.set(0, 2.0) }

      context 'setting 0.5' do
        let(:set_load) { storage.set_load(1, 0.5) }

        it 'reduces stored amount by 0.5' do
          expect { set_load }
            .to change { storage.reserve.at(1) }
            .from(2.0).to(1.5)
        end

        it 'returns 0.5' do
          expect(set_load).to eq(0.5)
        end

        it 'sets a load of 0.5' do
          set_load
          expect(storage.load_curve.get(1)).to eq(0.5)
        end

        it 'incurs no production' do
          expect { set_load }.to_not change { storage.production }
        end

        context 'with an output efficiency of 0.4' do
          let(:attrs) { super().merge(output_efficiency: 0.4) }

          it 'reduces stored amount by 1.25' do
            expect { set_load }
              .to change { storage.reserve.at(1) }
              .from(2.0).to(0.75)
          end

          it 'sets a load of 0.5' do
            expect(set_load).to eq(0.5)
          end

          it 'returns 0.5' do
            set_load
            expect(storage.load_curve.get(1)).to eq(0.5)
          end
        end # with an output efficiency of 0.4
      end # setting 0.5
    end # set_load

    # --

    describe 'decay' do
      context 'with 2.0 stored' do
        before { storage.assign_excess(0, 2.0) }

        context 'and no decay proc provided' do
          it 'does not decay the stored energy' do
            expect(storage.max_load_at(1)).to eq(2.0)
          end
        end

        context 'and a decay proc returning 1.0' do
          let(:attrs) { super().merge(decay: ->(*) { 1.0 }) }

          it 'leaves 1.0 energy remaining in the next point' do
            expect(storage.max_load_at(1)).to eq(1.0)
          end
        end

        context '2 units' do
          let(:attrs) { super().merge(number_of_units: 2) }

          context 'and no decay proc' do
            it 'does not decay the stored energy' do
              expect(storage.max_load_at(1)).to eq(2.0)
            end
          end

          context 'and a decay proc returning 0.75' do
            let(:attrs) { super().merge(decay: ->(*) { 0.5 }) }

            it 'leaves 0.5 energy remaining in the next point' do
              expect(storage.max_load_at(1)).to eq(1.0)
            end
          end
        end

        context 'and a decay proc returning 3.0' do
          let(:attrs) { super().merge(decay: ->(*) { 3.0 }) }

          it 'leaves no energy remaining in the next point' do
            expect(storage.max_load_at(1)).to be_zero
          end
        end
      end # with 2.0 stored
    end # decay

  end # Flex::Storage
end # Merit
