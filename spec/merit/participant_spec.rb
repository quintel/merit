require 'spec_helper'

module Merit

  describe Participant do

    let(:participant){ Participant.new(key: :foo,
                                       effective_output_capacity: 1,
                                       marginal_costs: 2,
                                       availability: 3
                                      ) }

    describe '#new' do
      it 'should accept a hash with key/values' do
      end
      it 'should remember key, capacity, etc.' do
        expect(participant.key).to eql(:foo)
        expect(participant.effective_output_capacity).to eql(1)
        expect(participant.marginal_costs).to eql(2)
        expect(participant.availability).to eql(3)
      end
      it 'should raise MissingAttributeError when key misses' do
        expect(->{ Participant.new({}) }).to raise_error(MissingAttributeError)
      end
    end

  end

end


