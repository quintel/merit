require 'spec_helper'

module Merit

  describe Storage do

    let(:storage) do
      Storage.new(
        key: :foo,
        capacity: 100,
        max_input: 40,
        max_output: 50,
        number_of_units: 2
      )
    end

    subject { storage }

    it { should respond_to(:capacity) }
    it { should respond_to(:max_input) }
    it { should respond_to(:max_output) }
    it { should respond_to(:number_of_units)}
    it { should respond_to(:utilization) }
    it { should respond_to(:fixed_costs_per_unit) }

    describe "#new" do
      it "remembers more attributes than basic participants" do
        expect(storage.key).to eql(:foo)
        expect(storage.max_input).to eql(40)
        expect(storage.max_output).to eql(50)
        expect(storage.capacity).to eql(100)
        expect(storage.utilization).to eql(0.0)
        expect(storage.fixed_costs_per_unit).to eql(500)
      end
    end

    describe "#available_capacity" do
      it "returns the difference between capacity and utilization" do
        storage.utilization = 60
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

    describe "#load_curve" do
      it "it settable by the merit order" do
        merit = Merit::Order.new
        merit.add(storage)
        merit.participant(:foo).load_curve = LoadCurve.new((1..3).to_a)
        expect(storage.load_curve.to_a).to eql [1,2,3]
      end

      it "is adaptable and extendable for the merit order" do
        merit = Merit::Order.new
        merit.add(storage)
        merit.participant(:foo).load_curve.set(0, 1)
        expect(storage.load_curve.to_a[0]).to eql(1)
      end
    end

  end # describe Storage
end #module Merit
