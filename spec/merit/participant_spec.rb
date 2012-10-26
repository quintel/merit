require 'spec_helper'

module Merit

  describe Participant do

    describe '#new' do
      it 'should accept a hash with key/values' do
        participant = Participant.new(key: 'coal')
      end
    end

  end

end


