require 'spec_helper'

module Merit

  describe MustRunProducer do

    let(:attrs) do
      {
        key:                      :households_solar_pv_solar_radiation,
        marginal_costs:           0.0,
        output_capacity_per_unit: 0.001245,
        number_of_units:          51023.14018,
        availability:             0.98,
        fixed_costs_per_unit:     222.9245208,
        fixed_om_costs_per_unit:  35.775,
        load_profile:             LoadProfile.new([0.05]),
        full_load_hours:          1050
      }
    end

    describe 'attrs' do
      it 'should be a Hash' do
        expect(attrs).to be_a(Hash)
      end
    end

    describe '#new' do
      it 'should not raise an error when all the attributes are there' do
        expect(->{ MustRunProducer.new(attrs) }).to_not raise_error
      end
      context 'should raise an error when any of those' do
        attributes = [:key, :output_capacity_per_unit, :number_of_units,
         :availability, :fixed_costs_per_unit, :fixed_om_costs_per_unit,
         :load_profile, :full_load_hours]
        attributes.each do |attribute|
          it "should raise an error when #{attribute} is missing" do
            attrs.delete(attribute)

            expect { MustRunProducer.new(attrs) }.to \
              raise_error(MissingAttributeError)
          end
        end
      end

      it 'should raise an error when there is no cost data' do
        attrs.delete(:marginal_costs)
        expect { MustRunProducer.new(attrs) }.to raise_error(NoCostData)
      end
    end

    describe '#to_s' do
      it 'should display name of subclass' do
        expect(MustRunProducer.new(attrs).to_s).to match('MustRun')
      end
    end # describe #to_s

  end # describe MustRunProducer
end # module Merit
