require 'spec_helper'

module Merit

  describe User, '.create' do
    it 'given invalid options, raises an error' do
      expect { User.create({}) }.to raise_error(Merit::UnknownDemandError)
    end
  end

  describe User, '.new' do
    it 'is not allowed' do
      expect { User.new(key: :nope) }.to raise_error(NoMethodError)
    end
  end

  describe User::TotalConsumption do
    def tc_user(options = {})
      User.create(options.merge(
        key: :total_demand,
        load_profile: LoadProfile.new('', [1.0])
      ))
    end

    describe '#load_curve' do
      let(:user) { tc_user(total_consumption: 300 * 10 ** 9) }

      it 'should return a load curve' do
        expect(user.load_curve).to be_a(Merit::Curve)
      end
    end #describe #load_curve

    describe '#load_at' do
      let(:user) { tc_user(total_consumption: 300 * 10 ** 9) }

      it 'should return a nice number' do
        expect(user.load_at(117)).to be > 0
      end
    end

    describe '#load_between' do
      let(:user) { tc_user(total_consumption: 210 * 10 ** 9) }

      it 'should return the total load between the two points' do
        expect(user.load_between(50, 52)).to be_within(0.01).of(
          user.load_at(50) + user.load_at(51) + user.load_at(52)
        )
      end
    end

  end #describe User::TotalConsumption

  describe User::WithCurve do
    let(:curve) do
      day = [
         0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
         12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23
      ].map(&:to_f)

      Merit::Curve.new(day * 365)
    end

    let(:user) { User.create(key: :with_curve, load_curve: curve) }

    describe '#load_curve' do
      it 'should return the load curve we provided' do
        expect(user.load_curve).to eq(curve)
      end
    end # describe #load_curve

    describe '#load_at' do
      it 'should return a nice number' do
        expect(user.load_at(23 + 14)).to eq(13) # 14th hour of the second day
      end
    end # load_at

    describe '#load_between' do
      it 'should return the total load between the two points' do
        expect(user.load_between(34, 36)).to eq(
          user.load_at(34) + user.load_at(35) + user.load_at(36)
        )
      end
    end # @load_between
  end # User::WithCurve

end #module Merit
