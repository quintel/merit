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
  end
end
