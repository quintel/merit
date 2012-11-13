require 'spec_helper'

module Merit

  describe User do

    let(:user){ User.new(key: :total_demand) }
 
    describe '#new' do

      it 'should accept a load curve with a load profile' do
        expect(->{ user }).to_not raise_error
      end

    end # describe #new

    describe '#load_curve' do

      context 'no total_consumption given' do
        it 'should return a load_curve for it' do
          expect(->{ user.load_curve }).to raise_error(UnknownDemandError)
        end
      end

      context 'total_consumption given' do
        it 'should return a load curve' do
          user.total_consumption = 300 * 10**9
          expect(->{ user.load_curve }).to_not raise_error
        end
      end

    end #describe #load_curve

  end #describe User

end #module Merit
