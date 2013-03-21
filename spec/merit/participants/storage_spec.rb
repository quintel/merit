require 'spec_helper'

module Merit
  
  describe Storage do

    let(:storage) do
      Storage.new(
        key: :foo,
        capacity: 100,
        max_input: 40,
        max_output: 50
      )
    end

    subject { storage }

    it { should respond_to(:capacity) }
    it { should respond_to(:max_input) }
    it { should respond_to(:max_output) }

    describe "#new" do
      it "remembers more attributes than basic participants" do
        expect(storage.key).to eql(:foo)
        expect(storage.max_input).to eql(40)
        expect(storage.max_output).to eql(50)
      end
    end

    describe "subject" do
      
    end
  end # describe Storage
end #module Merit
