require 'spec_helper'

module Merit

  describe Producer do

    let(:producer) do
      Producer.new(
        key:                      :foo,
        marginal_costs:           11.1,
        output_capacity_per_unit: 1,
        number_of_units:          5,
        availability:             0.95,
        fixed_costs_per_unit:     222.9245208,
        fixed_om_costs_per_unit:  35.775,
        load_profile:             LoadProfile.new([0.05]),
        full_load_hours:          1050
       )
    end

    describe '#new' do
      it 'should remember (more attributes than basic participants)' do
        expect(producer.key).to eql(:foo)
        expect(producer.load_profile).to be_kind_of(LoadProfile)
        expect(producer.output_capacity_per_unit).to eql(1)
        expect(producer.marginal_costs).to eql(11.1)
        expect(producer.availability).to eql(0.95)
        expect(producer.full_load_hours).to eql(1050)
      end
    end

    describe '#full_load_hours' do
      it 'should be the same as inputted, if it was input' do
        expect(producer.full_load_hours).to eql 1050
      end

      context 'when no explicit value is set' do
        let(:producer) do
          Producer.new(
            key: :bar,
            marginal_costs: 11.1,
            output_capacity_per_unit: 1600,
            availability: 0.9,
            fixed_costs_per_unit: 222.9245208,
            fixed_om_costs_per_unit: 35.775,
            number_of_units: 0.31875
          ).tap { |p| allow(p).to receive(:production).and_return(14475023999.999998) }
        end

        it 'should be 8760 * availability for a continuously on dispatchable' do
          expect(producer.full_load_hours).to eql 8760 * 0.9
        end

        context 'when effective output capacity is zero' do
          before { allow(producer).to receive(:output_capacity_per_unit).and_return(0.0) }

          it 'is zero' do
            expect(producer.full_load_hours).to eql(0.0)
          end
        end

        context 'when number of units is zero' do
          before { allow(producer).to receive(:number_of_units).and_return(0.0) }

          it 'is zero' do
            expect(producer.full_load_hours).to eql(0.0)
          end
        end
      end # when no explicit value is set
    end # full_load_hours

    describe '#production' do
      before(:each) do
        producer.load_curve.set(0, 10.0)
        producer.load_curve.set(1, 50.0)
      end
      it 'is based on the load curve' do
        expect(producer.production).to eql(60.0 * 3600)
      end
      it 'should return MJs if no unit given' do
        expect(producer.production).to eql(60.0 * 3600)
      end
      it 'should return MJs if unit is :mj' do
        expect(producer.production(:mj)).to eql(60.0 * 3600)
      end
      it 'should return MWHs if unit is :mwh' do
        expect(producer.production(:mwh)).to eql(60.0)
      end
      it 'should raise an error if unit is unknown' do
        expect(->{ producer.production(:foo) }).to raise_error(RuntimeError)
      end
    end

    describe '#load_curve' do
      it 'should be settable by the merit order' do
        merit = Merit::Order.new
        merit.add(producer)
        merit.participants[:foo].load_curve = Curve.new((1..3).to_a)
        expect(producer.load_curve.to_a).to eql [1,2,3]
      end
      it 'should be adaptable and extendable for the merit order' do
        merit = Merit::Order.new
        merit.add(producer)
        merit.participants[:foo].load_curve.set(0, 1)
        expect(producer.load_curve.to_a[0]).to eql(1)
      end
    end

    describe '#max_load_curve' do
      context 'when a load profile is available' do
        it 'should be available' do
          expect(producer.max_load_curve)
        end

        it 'should be the product of max production and the load profile' do
          allow(producer).to receive(:max_production) { 1000 }

          expect(producer.max_load_curve.get(117)).
            to eql(producer.load_profile.values[117] * 1000)
        end
      end # when a load profile is available

      context 'when no load profile is avaiable' do
        before { producer.load_profile = nil }
        let(:load_curve) { producer.max_load_curve }

        it 'has Merit::POINTS elements' do
          expect(load_curve.length).to eql(Merit::POINTS)
        end

        it 'uses the output capacity at each point' do
          expect(producer.max_load_curve.first).
            to eql(producer.available_output_capacity)
        end
      end
    end

    describe '#spare_load_curve' do
      it 'is a Curve' do
        expect(producer.spare_load_curve).to be_a(Curve)
      end

      it 'describes the difference between maximum capacity and usage' do
        producer.max_load_curve.set(0, 10.0)
        producer.max_load_curve.set(1, 5.0)

        producer.load_curve.set(0, 5.0)
        producer.load_curve.set(1, 2.5)

        expect(producer.spare_load_curve.get(0)).to eql(5.0)
        expect(producer.spare_load_curve.get(1)).to eql(2.5)
      end
    end

    describe '#ramping_curve' do
      it 'is a Curve' do
        expect(producer.ramping_curve).to be_a(Curve)
      end
    end

    describe '#off_times' do
      it 'describes the points in which the producer creates no energy' do
        producer.load_curve.set(0, 5.0)
        producer.load_curve.set(1, 2.5)

        expect(producer.off_times).to eql(producer.load_curve.length - 2)
      end
    end

    describe '#average_load_curve' do
      it 'averages the points on the load curve' do
        producer.load_curve.set(0, 8760 * 2)
        expect(producer.average_load).to eql(2.0)
      end
    end

    describe '#load_profile' do
      it 'should contain the values' do
        expect(producer.load_profile.values.length).to eq(8760)
      end
    end

    describe '#max_production' do
      context 'when full load hours was not inputted' do
        it 'should return the correct outcome in MJ' do
          producer.instance_variable_set(:@full_load_hours, nil)
          expect(producer.max_production).to eql 149796000.0
        end
      end
      context 'when full load hours have been inputted' do
        it 'should return the correct outcome in MJ' do
          expect(producer.max_production).to eql 18900000
        end
      end
    end

    describe '#max_load_at(point_in_time)' do
      context 'given a load profile' do
        it 'should return the load_profile\'s value' do
          producer.load_profile = LoadProfile.new(Array.new(8760, 1))

          expect(producer.max_load_at(117)).to eql producer.max_production
        end
      end
      context 'given NO load profile' do
        it 'should return the available_output_capacity' do
          producer.load_profile = nil

          expect(producer.max_load_at(117)).to \
            eql producer.available_output_capacity
        end
      end
    end

    describe '#load_between' do
      context 'given a load profile' do
        it 'should return the total max load over the period' do
          producer.load_profile = LoadProfile.new(Array.new(8760, 1))

          expect(producer.load_between(50, 52)).to eql(
            producer.max_load_at(50) +
            producer.max_load_at(51) +
            producer.max_load_at(52))
        end
      end

      context 'given no load profile' do
        it 'returns the available output capacity over the period' do
          producer.load_profile = nil

          expect(producer.load_between(50, 52)).to eql(
            producer.max_load_at(50) +
            producer.max_load_at(51) +
            producer.max_load_at(52))
        end
      end
    end

    describe '#info' do
      it 'should produce some statistics about this producer' do
        output = capture_stdout { producer.info }
        expect(output).to be_a(String)
        expect(output).to match producer.key.to_s
      end
    end

  end # describe Producer

end # module Merit
