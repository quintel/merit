# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe LoadProfile do
    let(:profile) { described_class.new((1..8760).to_a) }

    describe '#new' do
      it 'is able to create a new one' do
        described_class.new([1, 2, 3])
      end

      it 'raises an error if the provided values are of incorrect length' do
        expect { described_class.new([1, 2, 3, 4, 5, 6, 7]) }
          .to raise_error(IncorrectLoadProfileError, /profile is malformatted/)
      end
    end

    describe '#load_file' do
      it 'loads a profile from file' do
        profile = described_class.load_file(fixture('solar_pv'))
      end

      it 'raises IncorrectLoadProfileError if LoadProfile is not a valid fraction' do
        allow(described_class.reader).to receive(:read).with(:foo) { (1..7).to_a }

        expect { described_class.load_file(:foo) }
          .to raise_error(/Invalid load profile at foo/)
      end

      it 'does not raise IncorrectLoadProfileError if LoadProfile is a valid fraction' do
        allow(described_class.reader).to receive(:read).with(:foo) { (1..2).to_a }
        expect { described_class.load_file(:foo) }.not_to(raise_error)
      end
    end

    describe '#values' do
      it 'returns the same values from file' do
        profile = described_class.load_file(fixture('solar_pv'))
        expect(profile.values.length).to eq(8760)
      end
    end

    describe '#to_s' do
      it 'contains the number of values' do
        expect(profile.to_s).to match('8760 values')
      end
    end

    describe '#surface' do
      it 'contains the surface below the values' do
        profile = described_class.new([1])
        expect(profile.surface).to be(8760)
      end
    end

    describe '#valid?' do
      it 'is true when the surface area is =~ 1/3600.0' do
        allow(profile).to receive(:surface).and_return(1 / 3600.0)
        expect(profile.valid?).to be
      end

      it 'is false when the surface area is !=~ 1/3600.0' do
        allow(profile).to receive(:surface).and_return(1 / 3500.0)
        expect(profile.valid?).not_to(be)
      end
    end

    describe '#draw' do
      it 'draws' do
        expect(profile.draw).not_to(be_empty)
      end
    end

    describe '.reader' do
      it 'uses the Curve reader' do
        allow(Curve).to receive(:reader).and_call_original
        described_class.reader

        expect(Curve).to have_received(:reader).once
      end
    end

    describe '.reader=' do
      it 'raises an error' do
        expect { described_class.reader = nil }
          .to raise_error(NotImplementedError, /Curve\.reader=/)
      end
    end
  end
end
