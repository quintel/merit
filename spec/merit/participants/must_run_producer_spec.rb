require 'spec_helper'

module Merit

  describe MustRunProducer do

    let(:must_run) do
      must_run = MustRunProducer.new(key: :coal,
                                     load_profile_key: :industry_chp,
                                     effective_output_capacity: 1,
                                     marginal_costs: 2,
                                     availability: 0.95,
                                     full_load_hours: 4
                                    )
    end

    describe '#new' do
      it 'should remember (more attributes than basic participants)' do
        expect(must_run.key).to eql(:coal)
        expect(must_run.load_profile_key).to eql(:industry_chp)
        expect(must_run.effective_output_capacity).to eql(1)
        expect(must_run.marginal_costs).to eql(2)
        expect(must_run.availability).to eql(0.95)
        expect(must_run.full_load_hours).to eql(4)
      end
    end

    describe '#load_curve' do
      it 'should be available' do
        expect(must_run.load_curve)
      end
    end

    describe '#load_profile' do
      it 'should contain the values' do
        expect(must_run.load_profile.values).to have(8760).values
      end
      it 'should raise an error is the load_profile is not known' do
        must_run = MustRunProducer.new(key: :foo, load_profile: 'weird-al')
        expect(->{ must_run.load_profile }) \
          .to raise_error(MissingLoadProfileError)
      end
    end

    describe '#total_production' do
      it 'should return the correct outcome in MJ' do
        expect(must_run.total_production).to eql 1 * 4 * 3600
      end
    end

    describe '#load_curve' do
      it 'should be the product of the energy production and the load profile' do
        must_run.stub(:total_production){ 1000 }
        expect(must_run.load_curve.values[117]).to \
          eql(must_run.load_profile.values[117] * 1000)
      end
    end

  end

end
