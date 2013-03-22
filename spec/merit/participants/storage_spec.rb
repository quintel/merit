require 'spec_helper'

module Merit

  describe Storage do

    let(:storage) do
      Storage.new(
        key: :foo,
        capacity: 100,
        max_input: 40,
        max_output: 50,
        utilization: 60
      )
    end

    subject { storage }

    it { should respond_to(:capacity) }
    it { should respond_to(:max_input) }
    it { should respond_to(:max_output) }
    it { should respond_to(:utilization) }

    describe "#new" do
      it "remembers more attributes than basic participants" do
        expect(storage.key).to eql(:foo)
        expect(storage.max_input).to eql(40)
        expect(storage.max_output).to eql(50)
        expect(storage.capacity).to eql(100)
        expect(storage.utilization).to eql(60)
      end

      it "has default utilization of 0" do
        storage = Storage.new(key: :test, capacity: 100, max_input: 20,
                              max_output: 10)
        expect(storage.utilization).to eql 0
      end
    end

    describe "#available_capacity" do
      it "returns the difference between capacity and utilization" do
        expect(storage.available_capacity).to eql 40
      end
    end

    describe "#max_load_at" do
      it "returns utilization if it is lower than max_output" do
        storage.utilization = storage.max_output - 10
        expect(storage.max_load_at(1)).to eql(storage.utilization)
      end

      it "returns max_output if it is lower than utilization" do
        storage.utilization = storage.max_output + 10
        expect(storage.max_load_at(1)).to eql(storage.max_output)
      end

    end

  end # describe Storage
end #module Merit
