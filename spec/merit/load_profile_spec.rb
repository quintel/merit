require 'spec_helper'

module Merit

  describe LoadProfile do

    let(:load_profile){ LoadProfile.new(:foo, (1..8760).to_a) }

    describe '#new' do
      it 'should be able to create a new one' do
        LoadProfile.new(:foo, [1,2,3])
      end
    end

    describe '#all' do
      it 'should load all keys' do
        expect(LoadProfile.all).to have_at_least(1).load_profiles
      end
      LoadProfile.all.each do |load_profile|
        it "#{load_profile.key} should be valid" do
          expect(load_profile).to be_valid
        end
      end
    end

    describe '.data-path' do
      context 'when in NL' do
        it 'points to nl directory' do
          expect(LoadProfile.data_path).to match /nl/
        end
      end
      context 'when in EU' do
        around(:each) do |example|
          Merit.within_area(:eu, &example)
        end
        it 'points to eu directory' do
          expect(LoadProfile.data_path).to match /eu/
        end
      end
    end

    describe '#load' do
      it 'should load a profile from file' do
        load_profile = LoadProfile.load(:solar_pv)
      end
      it 'should raise a MissingLoadProfileError if load profile does not exist' do
        expect(->{ LoadProfile.load(:foobar) }).to \
          raise_error(MissingLoadProfileError)
      end
      it 'should raise IncorrectLoadProfileError if LoadProfile is not a valid fraction' do
        LoadProfile.reader.stub(:read).with(:foo){ (1..7).to_a }
        expect(->{ LoadProfile.load(:foo) }).to \
          raise_error(IncorrectLoadProfileError)
      end
      it 'should not raise IncorrectLoadProfileError if LoadProfile is a valid fraction' do
        LoadProfile.reader.stub(:read).with(:foo){ (1..2).to_a }
        expect(->{ LoadProfile.load(:foo) }).to_not raise_error
      end
    end

    describe '#values' do
      it 'should return the same values from file' do
        load_profile = LoadProfile.load(:solar_pv)
        expect(load_profile.values).to have(8760).points
      end
    end

    describe '#to_s' do
      it 'should contain the number of values' do
        expect(load_profile.to_s).to match '8760 values'
      end
    end

    describe '#surface' do
      it 'should contain the surface below the values' do
        load_profile = LoadProfile.new(:foo, [1])
        expect(load_profile.surface).to eql(8760)
      end
    end

    describe '#valid?' do
      it 'should be true when the surface area is =~ 1/3600.0' do
        load_profile.stub(:surface){ 1/3600.0 }
        expect(load_profile.valid?).to be_true
      end
      it 'should be false when the surface area is !=~ 1/3600.0' do
        load_profile.stub(:surface){ 1/3500.0 }
        expect(load_profile.valid?).to be_false
      end
    end

    describe '#draw' do
      it 'should draw' do
        expect(load_profile.draw).to_not be_empty
      end
    end

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
    end

    describe LoadProfile::CachingReader do
      let(:reader) { LoadProfile::CachingReader.new }

      it 'reads the source file' do
        expect(reader.read('agriculture_chp')).to_not be_empty
        # Second call also works?
        expect(reader.read('agriculture_chp')).to_not be_empty
      end
    end

  end

end
