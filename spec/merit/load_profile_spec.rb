require 'spec_helper'

module Merit

  describe LoadProfile do

    let(:load_profile){ LoadProfile.new((1..8760)) }

    describe '#new' do
      it 'should be able to create a new one' do
        LoadProfile.new([1,2,3])
      end
    end

    describe '#load' do
      it 'should load a profile from file' do
        load_profile = LoadProfile.load(:solar_pv)
      end
    end

    describe '#values' do
      it 'should return the same values from file' do
        load_profile = LoadProfile.load(:solar_pv)
        expect(load_profile.values).to have(2190).points
      end
    end
  end

end
