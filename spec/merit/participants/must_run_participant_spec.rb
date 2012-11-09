# @type            = opts[:type]
# @capacity        = opts[:capacity]
# @marginal_costs  = opts[:marginal_costs]
# @availability    = opts[:availability]
# @full_load_hours = opts[:full_load_hours]

require 'spec_helper'

module Merit

  describe MustRunParticipant do

    let(:must_run) do
      must_run = MustRunParticipant.new(key: :coal,
                                        load_profile_key: :industry_chp,
                                        capacity: 1,
                                        marginal_costs: 2,
                                        availability: 3,
                                        full_load_hours: 4
                                       )
    end

    describe '#new' do
      it 'should remember (more than basic participants)' do
        expect(must_run.key).to eql(:coal)
        expect(must_run.load_profile_key).to eql(:industry_chp)
        expect(must_run.capacity).to eql(1)
        expect(must_run.marginal_costs).to eql(2)
        expect(must_run.availability).to eql(3)
        expect(must_run.full_load_hours).to eql(4)
      end
    end

    describe '#load_profile_values' do
      it 'should contain the values' do
        expect(must_run.load_profile.values).to have(8760).values
      end
      it 'should raise an error is the load_profile is not known' do
        must_run = MustRunParticipant.new(load_profile: 'weird-al')
        expect(->{ must_run.load_profile }) \
          .to raise_error(MissingLoadProfileError)
      end
    end

  end

end
