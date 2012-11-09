require 'spec_helper'

module Merit

  describe LoadProfile do

    let(:load_profile){ LoadProfile.new((1..8760)) }

    describe '#new' do
      it 'should be able to create a new one' do
        LoadProfile.new(:foo, [1,2,3])
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
        LoadProfile.stub!(:read_values_from_file).with(:foo){ (1..7).to_a }
        expect(->{ LoadProfile.load(:foo) }).to \
          raise_error(IncorrectLoadProfileError)
      end
      it 'should raise IncorrectLoadProfileError if LoadProfile is a valid fraction' do
        LoadProfile.stub!(:read_values_from_file).with(:foo){ (1..2).to_a }
        expect(->{ LoadProfile.load(:foo) }).to_not \
          raise_error(IncorrectLoadProfileError)
      end
    end

    describe '#values' do
      it 'should return the same values from file' do
        load_profile = LoadProfile.load(:solar_pv)
        expect(load_profile.values).to have(8760).points
      end
    end
  end

end
