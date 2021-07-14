# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe CollectionTable do
    let(:collection) { described_class.new([1, 2], %i[to_s floor]) }

    describe '#new' do
      it 'creates new one' do
      end
    end

    describe '#table' do
      it 'is a TerminalTable' do
        expect(collection.table).to be_a(Terminal::Table)
      end
    end

    describe '#round_if_number' do
      it 'rounds if it is numeric' do
        expect(collection.round_if_number(1.1)).to be(1)
      end

      it 'does not round if it is not numeric' do
        expect(collection.round_if_number('A')).to eql('A')
      end
    end
  end
end
