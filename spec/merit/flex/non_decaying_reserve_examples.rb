# frozen_string_literal: true

RSpec.shared_examples_for 'non-decaying reserve' do
  let(:reserve) { described_class.new }

  it 'starts empty' do
    expect(reserve.at(0)).to be_zero
  end

  describe '#to_s' do
    it 'includes the volume' do
      expect(reserve.to_s).to include('Infinity')
    end
  end

  describe '#inspect' do
    it 'includes the volume' do
      expect(reserve.inspect).to include('Infinity')
    end
  end

  describe 'computing frame 8760 with no prior values' do
    it 'does not raise an error' do
      expect { reserve.at(8760) }.not_to raise_error
    end

    it 'returns 0.0' do
      expect(reserve.at(8760)).to eq(0)
    end
  end

  describe 'computing frame 8760 with one prior value of 2.0' do
    before { reserve.set(0, 2.0) }

    it 'does not raise an error' do
      expect { reserve.at(8760) }.not_to raise_error
    end

    it 'returns 2.0' do
      expect(reserve.at(8760)).to eq(2.0)
    end
  end

  describe '#to_a' do
    before do
      8760.times do |frame|
        # Add 0, 1, 2, etc. This doesn't change the amount stored but assets that set assigns the
        # stored amount as expected.
        reserve.set(frame, frame.to_f)

        reserve.add(frame, 2.0)
        reserve.take(frame, 1.0)
      end
    end

    it 'returns the stored amount as an array' do
      expect(reserve.to_a).to eq(Array.new(8760) { |i| (i + 1).to_f })
    end
  end

  context 'when adding 3 in frame 0 and 2' do
    before do
      reserve.add(0, 3.0)
      reserve.add(2, 3.0)
    end

    it 'has 3 in frame 0' do
      # require 'pry'
      # binding.pry
      expect(reserve.to_a[0]).to eq(3)
    end

    it 'is empty in frame 1' do
      expect(reserve.to_a[1]).to eq(3)
    end

    it 'has 6 in frame 2' do
      expect(reserve.to_a[2]).to eq(6)
    end
  end

  context 'when adding 5 in frame 0' do
    before { reserve.add(0, 5.0) }

    it 'adds 5 in frame 0' do
      expect(reserve.at(0)).to eq(5.0)
    end

    it 'carries 5 over to the start of frame 1' do
      expect(reserve.at(1)).to eq(5.0)
    end

    context 'when adding 2.5 in frame 1' do
      before { reserve.add(0, 2.5) }

      it 'has 7.5 stored in frame 1' do
        expect(reserve.at(1)).to eq(7.5)
      end

      it 'carries 7.5 over to the start of frame 2' do
        expect(reserve.at(2)).to eq(7.5)
      end
    end

    context 'when taking 1.2 in frame 1' do
      let!(:taken) { reserve.take(0, 1.2) }

      it 'returns that 1.2 was taken' do
        expect(taken).to eq(1.2)
      end

      it 'has 3.8 stored in frame 1' do
        expect(reserve.at(1)).to eq(3.8)
      end

      it 'carries 3.8 over to frame 2' do
        expect(reserve.at(2)).to eq(3.8)
      end
    end

    context 'when taking 5.2 in frame 1' do
      let!(:taken) { reserve.take(0, 5.2) }

      it 'returns that 5.0 was taken' do
        expect(taken).to eq(5.0)
      end

      it 'has nothing stored in frame 1' do
        expect(reserve.at(1)).to be_zero
      end

      it 'carries nothing over to frame 2' do
        expect(reserve.at(2)).to be_zero
      end
    end
  end

  context 'with a volume of 2.0' do
    let(:reserve) { described_class.new(2.0) }

    context 'when adding 1.0' do
      let!(:added) { reserve.add(0, 1.0) }

      it 'returns 1.0' do
        expect(added).to eq(1.0)
      end

      it 'adds 1.0 to frame 0' do
        expect(reserve.at(0)).to eq(1.0)
      end

      it 'has 1.0 unfilled' do
        expect(reserve.unfilled_at(0)).to eq(1.0)
      end
    end

    context 'when adding 2.0' do
      let!(:added) { reserve.add(0, 2.0) }

      it 'returns 2.0' do
        expect(added).to eq(2.0)
      end

      it 'adds 2.0 to frame 0' do
        expect(reserve.at(0)).to eq(2.0)
      end

      it 'is full' do
        expect(reserve.unfilled_at(0)).to be_zero
      end
    end

    context 'when adding 2.1' do
      let!(:added) { reserve.add(0, 2.1) }

      it 'returns 2.0' do
        expect(added).to eq(2.0)
      end

      it 'adds 2.0 to frame 0' do
        expect(reserve.at(0)).to eq(2.0)
      end

      it 'is full' do
        expect(reserve.unfilled_at(0)).to be_zero
      end
    end
  end
end
