require 'spec_helper'

module Merit

  describe Producer do

    let(:producer) do
      Producer.new(
        key:                       :coal,
        load_profile_key:          :industry_chp,
        effective_output_capacity: 1,
        marginal_costs:            2,
        availability:              0.95,
        number_of_units:           2,
        full_load_hours:           4
       )
    end

    describe '#new' do
      it 'should remember (more attributes than basic participants)' do
        expect(producer.key).to eql(:coal)
        expect(producer.load_profile_key).to eql(:industry_chp)
        expect(producer.effective_output_capacity).to eql(1)
        expect(producer.marginal_costs).to eql(2)
        expect(producer.availability).to eql(0.95)
        expect(producer.full_load_hours).to eql(4)
      end
    end

    describe '#load_curve' do
      it 'should be settable by the merit order' do
        merit = Merit::Order.new
        merit.add(producer)
        merit.participant(:coal).load_curve = LoadCurve.new((1..3).to_a)
        expect(producer.load_curve.values).to eql [1,2,3]
      end
      it 'should be adaptable and extendable for the merit order' do
        merit = Merit::Order.new
        merit.add(producer)
        merit.participant(:coal).load_curve.values[0] = 1
        expect(producer.load_curve.values[0]).to eql 1
        expect(producer.load_curve.values[1]).to be_nil
      end
    end

    describe '#max_load_curve' do
      it 'should be available' do
        expect(producer.max_load_curve)
      end
      it 'should be the product of energy production and the load profile' do
        producer.stub(:total_production){ 1000 }
        expect(producer.max_load_curve.values[117]).to \
          eql(producer.load_profile.values[117] * 1000)
      end
    end

    describe '#load_profile' do
      it 'should contain the values' do
        expect(producer.load_profile.values).to have(8760).values
      end
      it 'should return nil if not available' do
        producer = Producer.new(key: :foo, load_profile: 'weird-al')
        expect(producer.load_profile).to be_nil
      end
    end

    describe '#total_production' do
      it 'should return the correct outcome in MJ' do
        expect(producer.total_production).to eql 1 * 4 * 3600 * 2
      end
    end

    describe '#max_load_at(point_in_time)' do
      context 'given a load profile' do
        it 'should return the load_profile\'s value' do
          ones = Array.new(8760,1)
          producer.stub_chain(:load_profile, :values).and_return(ones)
          expect(producer.max_load_at(117)).to eql producer.total_production
        end
      end
      context 'given NO load profile' do
        it 'should return the available_output_capacity' do
          producer.stub(:load_profile).and_return nil
          expect(producer.max_load_at(117)).to \
            eql producer.available_output_capacity
        end
      end
    end

  end

end
