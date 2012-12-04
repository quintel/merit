require 'spec_helper'

module Merit

  describe CollectionTable do

    let(:collection) { CollectionTable.new([1,2],[:to_s,:floor]) }

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
      it 'should round if it is numeric' do
        expect(collection.round_if_number(1.1)).to eql 1
      end
      it 'should not round if it is not numeric' do
        expect(collection.round_if_number("A")).to eql "A"
      end
    end
  end
end
