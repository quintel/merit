require 'spec_helper'

module Merit
  describe Flex::Base do
    let(:attrs) {{
      key: :a,
      output_capacity_per_unit: 2.0,
      input_capacity_per_unit: 2.0,
      number_of_units: 1
    }}

    context 'with no group or excess_share' do
      it 'is acceptable' do
        expect { Flex::Base.new(attrs) }.to_not raise_error
      end
    end

    context 'with group and excess_share' do
      let(:attrs) do
        super().merge(group: :a, excess_share: 1.0)
      end

      it 'is acceptable' do
        expect { Flex::Base.new(attrs) }.to_not raise_error
      end
    end

    context 'with excess_share and no group' do
      let(:attrs) do
        super().merge(excess_share: 1.0)
      end

      it 'is not acceptable' do
        expect { Flex::Base.new(attrs) }.to raise_error(MissingGroup)
      end
    end

    describe '#full_load_hours when number of units is zero' do
      let(:flex) do
        described_class.new(attrs.merge(input_capacity_per_unit: 1.0, number_of_units: 0.0))
      end

      it 'is zero' do
        expect(flex.full_load_hours).to eq(0)
      end
    end

    describe '#full_load_hours when input capacity is zero' do
      let(:flex) do
        described_class.new(attrs.merge(input_capacity_per_unit: 0.0, number_of_units: 1.0))
      end

      it 'is zero' do
        expect(flex.full_load_hours).to eq(0)
      end
    end

    describe '#full_load_hours when output capacity is 1 and input capacity is 2' do
      let(:attrs) do
        super().merge(output_capacity_per_unit: 1.0, number_of_units: 1.0)
      end

      let(:flex) do
        described_class.new(attrs)
      end

      context 'when receiving 2 for 50 hours' do
        before do
          50.times { |i| flex.assign_excess(i, 2.0) }
        end

        it 'is 50' do
          expect(flex.full_load_hours).to eq(50)
        end
      end

      context 'when receiving 1.5 for 75 hours' do
        before do
          75.times { |i| flex.assign_excess(i, 1.5) }
        end

        it 'is 56.25' do
          expect(flex.full_load_hours).to eq(56.25)
        end
      end

      context 'when receiving 2 for 50 hours and taking 1 for 100 hours' do
        before do
          50.times do |i|
            flex.assign_excess(i * 2, 2.0)
            flex.set_load(i * 2 + 1, 1.0)
          end
        end

        it 'is 50' do
          expect(flex.full_load_hours).to eq(50)
        end
      end
    end
  end
end
