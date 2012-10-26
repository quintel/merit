require 'spec_helper'

module Merit

  describe Calculator do

    let(:calculator){ Calculator.new(LoadCurve.new) }

    describe "#new" do
      it "should be able to create one" do
        Calculator.new
      end
    end

    describe "#add_participant" do
      it "should be able to add a participant" do
        calculator.add_participant(Participant.new)
        expect(calculator.participants).to have(1).participant
      end
    end

    describe "#inspect" do
      it "should contain the number of participants" do
        expect(calculator.to_s).to match("0")
        calculator.add_participant(Participant.new)
        expect(calculator.to_s).to match("1")
      end
    end

    describe "#load_curve" do
      it "should return nil when nothing has been set" do
        calculator = Calculator.new
        expect(calculator.load_curve).to be_nil
      end

      it "should return the LoadCurve when set" do
        load_curve = LoadCurve.new
        calculator.load_curve = load_curve
        expect(calculator.load_curve).to equal(load_curve)
      end

    end
  end

end
