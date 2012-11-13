require 'spec_helper'

module Merit

  describe VolatileProducer do

    let(:dispatchable) do
      DispatchableProducer.new(
        key:                       :gas,
        marginal_costs:            65.90,
        effective_output_capacity: 3824,
        number_of_units:           4.82,
        availability:              0.89,
        fixed_costs:               29_000_000
      )
    end

    describe '#new' do
      it 'should remember all this stuff' do
        expect(dispatchable.key).to                       eql :gas
        expect(dispatchable.marginal_costs).to            eql 65.90
        expect(dispatchable.effective_output_capacity).to eql 3824
        expect(dispatchable.number_of_units).to           eql 4.82
        expect(dispatchable.availability).to              eql 0.89
        expect(dispatchable.fixed_costs).to               eql 29_000_000
      end
    end

    describe '#max_load' do
      it 'should be the same as effective output cap * units * availability' do
        expect(dispatchable.max_load).to \
          eql(3824 * 4.82 * 0.89)
      end
    end

  end

end
