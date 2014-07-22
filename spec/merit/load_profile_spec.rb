require 'spec_helper'

module Merit
  describe LoadProfile do
    let(:profile) { LoadProfile.new('data/foo', (1..8760).to_a) }

    describe '#new' do
      it 'should be able to create a new one' do
        LoadProfile.new('data/foo', [1,2,3])
      end
    end # new

    describe '#load' do
      it 'should load a profile from file' do
        profile = LoadProfile.load(fixture('solar_pv'))
      end

      it 'should raise a MissingLoadProfileError if load profile does not exist' do
        expect(->{ LoadProfile.load(fixture('nope')) }).
          to raise_error(MissingLoadProfileError)
      end

      it 'should raise IncorrectLoadProfileError if LoadProfile is not a valid fraction' do
        allow(LoadProfile.reader).to receive(:read).with(:foo) { (1..7).to_a }

        expect { LoadProfile.load(:foo) }.
          to raise_error(IncorrectLoadProfileError)
      end

      it 'should not raise IncorrectLoadProfileError if LoadProfile is a valid fraction' do
        allow(LoadProfile.reader).to receive(:read).with(:foo){ (1..2).to_a }
        expect { LoadProfile.load(:foo) }.to_not raise_error
      end
    end # load

    describe '#values' do
      it 'should return the same values from file' do
        profile = LoadProfile.load(fixture('solar_pv'))
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
        profile = LoadProfile.new(:foo, [1])
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
      after { LoadProfile.reader = LoadProfile::Reader.new }

      context 'when no reader has been set' do
        before { LoadProfile.instance_variable_set(:@reader, nil) }

        it 'returns the default Reader' do
          expect(LoadProfile.reader).to     be_a(LoadProfile::Reader)
          expect(LoadProfile.reader).to_not be_a(LoadProfile::CachingReader)
        end
      end # when no reader has been set

      context 'when setting a custom reader' do
        it 'sets the reader instance' do
          reader = LoadProfile::CachingReader.new
          LoadProfile.reader = reader

          expect(LoadProfile.reader).to eql(reader)
        end
      end # when setting a custom reader
    end # .reader

    describe LoadProfile::CachingReader do
      let(:reader) { LoadProfile::CachingReader.new }

      it 'reads the source file' do
        expect(reader.read(fixture('solar_pv'))).to_not be_empty

        # Second call also works?
        expect(reader.read(fixture('solar_pv'))).to_not be_empty
      end

      it 'caches based on path, not filename' do
        one = reader.read(fixture('solar_pv'))
        two = reader.read(fixture('subdir/solar_pv'))

        expect(one).to_not eql(two)
      end
    end # LoadProfile::CachingReader

  end # LoadProfile
end # Merit
