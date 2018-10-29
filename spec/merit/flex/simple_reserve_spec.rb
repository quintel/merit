# frozen_string_literal: true

require 'spec_helper'
require_relative 'non_decaying_reserve_examples'

module Merit
  RSpec.describe Flex::SimpleReserve do
    let(:reserve) { described_class.new }

    include_examples 'non-decaying reserve'

    describe 'with a decay' do
      let(:reserve) { described_class.new { |*| 2 }}

      it 'raises an error' do
        expect { reserve }.to raise_error(/decay not supported/i)
      end
    end
  end
end
