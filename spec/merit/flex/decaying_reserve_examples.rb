# frozen_string_literal: true

RSpec.shared_examples_for 'decaying reserve' do
  describe 'with a decay which subtracts 2' do
    let(:reserve) { described_class.new { |*| 2 } }

    it 'has nothing in frame 0' do
      expect(reserve.at(0)).to be_zero
    end

    it 'has nothing in frame 1' do
      expect(reserve.at(1)).to be_zero
    end

    context 'when starting with 10 and skipping frames' do
      before { reserve.set(0, 5) }

      it 'has 5 in frame 0' do
        expect(reserve.at(0)).to eq(5)
      end

      it 'has 3 in frame 1' do
        expect(reserve.at(1)).to eq(3)
      end

      it 'has 1 in frame 2' do
        expect(reserve.at(2)).to eq(1)
      end

      it 'has 0 in frame 3' do
        expect(reserve.at(3)).to eq(0)
      end

      it 'returns the stored value for each frame when calling to_a' do
        reserve.at(8759)
        expect(reserve.to_a.take(6)).to eq([5, 3, 1, 0, 0, 0])
      end
    end

    context 'when adding 4.0' do
      let!(:added) { reserve.add(0, 4.0) }

      it 'returns 4.0' do
        expect(added).to eq(4.0)
      end

      it 'adds 4.0 to frame 0' do
        expect(reserve.at(0)).to eq(4)
      end

      context 'when calculating in frame 1' do
        it 'has 2.0 remaining' do
          expect(reserve.at(1)).to eq(2)
        end

        context 'with 1.0 added' do
          before { reserve.add(1, 1.0) }

          it 'has 3.0 remaining in frame 1' do
            expect(reserve.at(1)).to eq(3)
          end

          it 'has 1.0 remaining in frame 2' do
            expect(reserve.at(2)).to eq(1)
          end

          it 'has nothing remaining in frame 3' do
            expect(reserve.at(3)).to be_zero
          end
        end
      end

      context 'when calculating in frame 2' do
        it 'has zero remaining' do
          expect(reserve.at(2)).to be_zero
        end

        context 'with 1.0 added' do
          before { reserve.add(2, 1.0) }

          it 'has 1.0 in the reserve' do
            expect(reserve.at(2)).to eq(1.0)
          end
        end
      end
    end

    describe 'with a decay which subtracts 10%' do
      let(:reserve) { described_class.new { |_, amt| amt * 0.1 } }

      context 'with 4.0 stored' do
        before { reserve.add(0, 4.0) }

        it 'has 4.0 stored in frame 0' do
          expect(reserve.at(0)).to eq(4.0)
        end

        it 'has 3.6 stored in frame 1' do
          expect(reserve.at(1)).to eq(3.6)
        end

        it 'has 3.24 stored in frame 2' do
          expect(reserve.at(2)).to eq(3.24)
        end
      end
    end

    describe 'with a decay which subtracts 2 in even-numbered frames' do
      let(:reserve) do
        described_class.new { |frame, _| frame.even? ? 2.0 : 0 }
      end

      context 'with 4.0 stored' do
        before { reserve.add(0, 4.0) }

        it 'has 4.0 stored in frame 0' do
          expect(reserve.at(0)).to eq(4.0)
        end

        it 'has 4.0 stored in frame 1' do
          expect(reserve.at(1)).to eq(4.0)
        end

        it 'has 2.0 stored in frame 2' do
          expect(reserve.at(2)).to eq(2.0)
        end

        it 'has 2.0 stored in frame 3' do
          expect(reserve.at(3)).to eq(2.0)
        end

        it 'has nothing stored in frame 4' do
          expect(reserve.at(4)).to be_zero
        end
      end
    end
  end
end
