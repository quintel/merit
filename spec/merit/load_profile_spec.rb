require 'spec_helper'

module Merit
  describe LoadProfile do
    let(:profile) { LoadProfile.new((1..8760).to_a) }

    describe '#new' do
      it 'should be able to create a new one' do
        LoadProfile.new([1,2,3])
      end

      it 'raises an error if the provided values are of incorrect length' do
        expect { LoadProfile.new([1, 2, 3, 4, 5, 6, 7]) }.
          to raise_error(IncorrectLoadProfileError, /profile is malformatted/)
      end
    end # new

    describe '#load_file' do
      it 'should load a profile from file' do
        profile = LoadProfile.load_file(fixture('solar_pv'))
      end

      it 'should raise IncorrectLoadProfileError if LoadProfile is not a valid fraction' do
        allow(LoadProfile.reader).to receive(:read).with(:foo) { (1..7).to_a }

        expect { LoadProfile.load_file(:foo) }.
          to raise_error(IncorrectLoadProfileError, /Load profile at foo/)
      end

      it 'should not raise IncorrectLoadProfileError if LoadProfile is a valid fraction' do
        allow(LoadProfile.reader).to receive(:read).with(:foo){ (1..2).to_a }
        expect { LoadProfile.load_file(:foo) }.to_not raise_error
      end
    end # load

    describe '#values' do
      it 'should return the same values from file' do
        profile = LoadProfile.load_file(fixture('solar_pv'))
        expect(profile.values.length).to eq(8760)
      end
    end # values

    describe '#to_s' do
      it 'should contain the number of values' do
        expect(profile.to_s).to match '8760 values'
      end
    end # to_s

    describe '#surface' do
      it 'should contain the surface below the values' do
        profile = LoadProfile.new([1])
        expect(profile.surface).to eql(8760)
      end
    end # surface

    describe '#valid?' do
      it 'should be true when the surface area is =~ 1/3600.0' do
        allow(profile).to receive(:surface).and_return(1/3600.0)
        expect(profile.valid?).to be
      end

      it 'should be false when the surface area is !=~ 1/3600.0' do
        allow(profile).to receive(:surface).and_return(1/3500.0)
        expect(profile.valid?).to_not be
      end
    end # valid?

    describe '#draw' do
      it 'should draw' do
        expect(profile.draw).to_not be_empty
      end
    end # draw

    describe '.reader' do
      it 'uses the Curve reader' do
        allow(Curve).to receive(:reader).and_call_original
        LoadProfile.reader

        expect(Curve).to have_received(:reader).once
      end
    end

    describe '.reader=' do
      it 'raises an error' do
        expect { LoadProfile.reader = nil }
          .to raise_error(NotImplementedError, /Curve\.reader=/)
      end
    end

  end # LoadProfile
end # Merit
