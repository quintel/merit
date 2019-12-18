# frozen_string_literal: true

require 'spec_helper'
require_relative 'non_decaying_reserve_examples'

module Merit
  RSpec.describe Flex::SimpleReserve do
    let(:reserve) { described_class.new }

    include_examples 'non-decaying reserve'

    # describe 'with a decay' do
    #   let(:reserve) { described_class.new { |*| 2 } }

    #   it 'raises an error' do
    #     expect { reserve }.to raise_error(/decay not supported/i)
    #   end
    # end

    describe 'with a decay which subtracts 2' do
      let(:reserve) { described_class.new { |*| 2 } }

      it 'has nothing in frame 0' do
        expect(reserve.at(0)).to be_zero
      end

      it 'has nothing in frame 1' do
        expect(reserve.at(1)).to be_zero
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
    end
  end
end
