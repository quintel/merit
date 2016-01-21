require 'spec_helper'

module Merit
  describe Storage::Base do
    let(:attrs) {{
      key: :p2p,
      number_of_units: 1,
      output_capacity_per_unit: 10.0,
      input_efficiency: 1.0,
      output_efficiency: 1.0,
      volume_per_unit: 10.0
    }}

    let(:storage) { Storage::Base.new(attrs) }

    # --

    describe 'available_at' do
      context 'when empty' do
        it 'returns zero' do
          expect(storage.available_at(0)).to be_zero
        end
      end # when empty

      context 'with 1.0 stored' do
        before { storage.store(0, 1.0) }

        context 'and capacity: 10.0' do
          it 'returns 1.0' do
            expect(storage.available_at(1)).to eq(1.0)
          end

          context 'and output_efficiency: 0.75' do
            let(:attrs) { super().merge(output_efficiency: 0.75) }

            it 'returns 0.75' do
              expect(storage.available_at(1)).to eq(0.75)
            end
          end
        end # and capacity: 10.0

        context 'and capacity: 0.5' do
          let(:attrs) { super().merge(output_capacity_per_unit: 0.5) }

          # We have to store 1.0x2 in order to store 1.0 (0.5 capacity is the
          # limiting factor for this tech).
          before { storage.store(1, 1.0) }

          it 'returns 0.5' do
            expect(storage.available_at(2)).to eq(0.5)
          end

          context 'and output_efficiency: 0.75' do
            let(:attrs) { super().merge(output_efficiency: 0.75) }

            it 'returns 0.5' do
              expect(storage.available_at(2)).to eq(0.5)
            end
          end
        end # and capacity: 0.5
      end # with 1.0 stored
    end # available_at

    # --

    describe 'store' do
      context 'storing 2.0' do
        context 'with nothing stored' do
          let(:store_load) { storage.store(0, 2.0) }

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
        end # with nothing stored

        context 'with 8.0 already stored' do
          before { storage.reserve.add(0, 8.0) }

          let(:store_load) { storage.store(1, 2.0) }

          it 'stores 2.0' do
            expect { store_load }
              .to change { storage.reserve.at(1) }.from(8.0).to(10.0)
          end

          it 'returns 2.0' do
            expect(storage.store(1, 2.0)).to eq(2.0)
          end

          it 'sets a load of -2.0' do
            store_load
            expect(storage.load_curve.get(1)).to eq(-2.0)
          end
        end # with 8.0 already stored

        context 'with 9.0 already stored' do
          before { storage.reserve.add(0, 9.0) }

          let(:store_load) { storage.store(1, 2.0) }

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
        end # with 9.0 already stored

        context 'with an availability of 0.1' do
          let(:attrs) { super().merge(availability: 0.1) }
          let(:store_load) { storage.store(1, 2.0) }

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

          let(:store_load) { storage.store(1, 2.0) }

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
          let(:store_load) { storage.store(1, 2.0) }

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

        context 'with a capacity of 0.5' do
          let(:attrs) { super().merge(output_capacity_per_unit: 0.5) }
          let(:store_load) { storage.store(1, 2.0) }

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
        end # with a capacity of 0.5

        context 'with a capacity of 0.5 and input efficiency of 0.75' do
          let(:attrs) do
            super().merge(
              output_capacity_per_unit: 0.5,
              input_efficiency: 0.75
            )
          end

          let(:store_load) { storage.store(1, 2.0) }

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
        end # with a capacity of 0.5 and input efficiency of 0.75
      end # storing 2.0
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
  end # Storage::Base
end # Merit
