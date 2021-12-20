# frozen_string_literal: true

require 'spec_helper'

module Merit
  describe MustRunProducer do
    let(:attrs) do
      {
        key: :households_solar_pv_solar_radiation,
        marginal_costs: 0.0,
        output_capacity_per_unit: 0.001245,
        number_of_units: 51_023.14018,
        availability: 0.98,
        fixed_costs_per_unit: 222.9245208,
        fixed_om_costs_per_unit: 35.775,
        load_profile: LoadProfile.new([0.05]),
        full_load_hours: 1050
      }
    end

    describe 'attrs' do
      it 'is a Hash' do
        expect(attrs).to be_a(Hash)
      end
    end

    include_examples 'a producer' do
      let(:producer) { described_class.new(attrs) }
    end

    describe '#new' do
      it 'does not raise an error when all the attributes are there' do
        expect(-> { described_class.new(attrs) }).not_to(raise_error)
      end

      context 'should raise an error when any of those' do
        attributes = %i[key load_profile full_load_hours]
        attributes.each do |attribute|
          it "raises an error when #{attribute} is missing" do
            attrs.delete(attribute)

            expect { described_class.new(attrs) }.to \
              raise_error(MissingAttributeError)
          end
        end
      end

      it 'raises an error when there is no cost data' do
        attrs.delete(:marginal_costs)
        expect { described_class.new(attrs) }.to raise_error(NoCostData)
      end
    end

    describe '#to_s' do
      it 'displays name of subclass' do
        expect(described_class.new(attrs).to_s).to match('MustRun')
      end
    end
  end
end
