# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe Participant do
    let(:participant)  do
      described_class.new(key: :foo,
                          effective_output_capacity: 1,
                          marginal_costs: 2,
                          availability: 3)
    end

    describe '#new' do
      it 'remembers key' do
        expect(participant.key).to be(:foo)
      end

      it 'raises MissingAttributeError when key misses' do
        expect(-> { described_class.new({}) }).to raise_error(MissingAttributeError)
      end
    end
  end
end
