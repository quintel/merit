# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Merit::Flex::LoadShifting::Flexible do
  let(:limiting_curve) { [1.0] * 8760 }
  let(:deficit_capacity) { nil }

  let(:part) do
    described_class.new(
      FactoryBot.attributes_for(:dispatchable).merge(
        key: :load_shaving,
        output_capacity_per_unit: 1.0,
        limiting_curve: limiting_curve,
        deficit_capacity: deficit_capacity
      )
    )
  end

  context 'with a curve limit of 2.0' do
    let(:limiting_curve) { [2.0] }

    before { part.set_load(0, 0.2) }

    context 'when outputting 0.2 in hour 0' do
      it 'has a load of 0.2 in hour 0' do
        expect(part.load_at(0)).to eq(0.2)
      end

      it 'has 0.8 output remaining' do
        expect(part.available_at(0)).to eq(0.8)
      end

      it 'has a deficit of 0.2' do
        expect(part.deficit).to eq(0.2)
      end
    end
  end

  context 'with a curve limit of 0.5' do
    let(:limiting_curve) { [0.5] }

    before { part.set_load(0, 0.2) }

    context 'when outputting 0.2 in hour 0' do
      it 'has a load of 0.2 in hour 0' do
        expect(part.load_at(0)).to eq(0.2)
      end

      it 'has 0.3 output remaining' do
        expect(part.available_at(0)).to eq(0.3)
      end

      it 'has a deficit of 0.2' do
        expect(part.deficit).to eq(0.2)
      end
    end
  end

  context 'when outputting 1.0 in hour 0' do
    before { part.set_load(0, 1.0) }

    it 'has a load of 1.0 in hour 0' do
      expect(part.load_at(0)).to eq(1)
    end

    it 'has no remaining output available' do
      expect(part.available_at(0)).to eq(0)
    end

    it 'does not allow assigning energy in the same hour' do
      expect(part.assign_excess(0, 1.0)).to eq(0)
    end

    it 'has a deficit of 1' do
      expect(part.deficit).to eq(1)
    end

    context 'when assigning 0 in hour 1' do
      let(:assign) { part.assign_excess(1, 0.0) }

      it 'sets no load' do
        assign
        expect(part.load_at(1)).to eq(0)
      end

      it 'returns zero' do
        expect(assign).to eq(0)
      end

      it 'has 1 available for output' do
        assign
        expect(part.available_at(1)).to eq(1)
      end

      it 'has a deficit of 1' do
        assign
        expect(part.deficit).to eq(1)
      end
    end

    context 'when assigning 0.5 in hour 1' do
      let(:assign) { part.assign_excess(1, 0.5) }

      it 'sets load to -0.5' do
        assign
        expect(part.load_at(1)).to eq(-0.5)
      end

      it 'returns 0.5' do
        expect(assign).to eq(0.5)
      end

      it 'has nothing available for output' do
        assign
        expect(part.available_at(1)).to eq(0)
      end

      it 'has a deficit of 0.5' do
        assign
        expect(part.deficit).to eq(0.5)
      end
    end

    context 'when assigning 0.5 twice in hour 1' do
      before do
        part.assign_excess(1, 0.5)
        part.assign_excess(1, 0.5)
      end

      it 'sets load to -1.0' do
        expect(part.load_at(1)).to eq(-1.0)
      end

      it 'cannot assign more' do
        expect(part.assign_excess(1, 1.0)).to eq(0)
      end

      it 'has nothing available for output' do
        expect(part.available_at(1)).to eq(0)
      end

      it 'has no deficit' do
        expect(part.deficit).to eq(0)
      end
    end

    context 'when assigning 2.0 in hour 1' do
      let(:assign) { part.assign_excess(1, 2.0) }

      it 'sets load to -1.0' do
        assign
        expect(part.load_at(1)).to eq(-1)
      end

      it 'returns 1.0' do
        expect(assign).to eq(1)
      end

      it 'has nothing available for output' do
        assign
        expect(part.available_at(1)).to eq(0)
      end
    end
  end

  context 'with a deficit cap of 0.5' do
    let(:deficit_capacity) { 0.5 }

    context 'when the participant has no deficit' do
      it 'has 0.5 available for output' do
        expect(part.available_at(1)).to eq(0.5)
      end
    end

    context 'when the participant has a deficit of 0.2' do
      before { part.set_load(0, 0.2) }

      it 'has 0.3 available for output' do
        expect(part.available_at(1)).to eq(0.3)
      end
    end

    context 'when the participant has a deficit of 0.5' do
      before { part.set_load(0, 0.5) }

      it 'has 0 available for output' do
        expect(part.available_at(1)).to eq(0)
      end
    end
  end

  context 'with a deficit cap of -1' do
    let(:deficit_capacity) { -1 }

    context 'when the participant has no deficit' do
      it 'has 0 available for output' do
        expect(part.available_at(0)).to eq(0)
      end
    end
  end

  context 'with deficit cap of 1.0' do
    let(:deficit_capacity) { 1.0 }

    context 'when outputting 1.0 in hour 0' do
      before { part.set_load(0, 1.0) }

      it 'works' do
        expect(part.available_at(0)).to eq(0)
      end
    end
  end

  # Asserts that assigning load does not increase deficit.
  context 'when setting output to 0.5 twice in hour 0' do
    before do
      part.set_load(0, 0.5)
      part.set_load(0, 0.5)
    end

    it 'has a load of 0.5 in hour 0' do
      expect(part.load_at(0)).to eq(0.5)
    end

    it 'has 0.5 remaining output available' do
      expect(part.available_at(0)).to eq(0.5)
    end

    it 'has a deficit of 0.5' do
      expect(part.deficit).to eq(0.5)
    end

    context 'when assigning 2.0 in hour 1' do
      let(:assign) { part.assign_excess(1, 2.0) }

      it 'sets load to -0.5' do
        assign
        expect(part.load_at(1)).to eq(-0.5)
      end

      it 'returns 0.5' do
        expect(assign).to eq(0.5)
      end
    end
  end

  # Asserts that assigning load does not increase deficit.
  context 'when setting output to 0.5 then 0.75 in the same hour' do
    before do
      part.set_load(0, 0.5)
      part.set_load(0, 0.75)
    end

    it 'has a load of 0.75 in hour 0' do
      expect(part.load_at(0)).to eq(0.75)
    end

    it 'has 0.25 remaining output available' do
      expect(part.available_at(0)).to eq(0.25)
    end

    it 'has a deficit of 0.75' do
      expect(part.deficit).to eq(0.75)
    end

    context 'when assigning 2.0 in hour 1' do
      let(:assign) { part.assign_excess(1, 2.0) }

      it 'sets load to -0.75' do
        assign
        expect(part.load_at(1)).to eq(-0.75)
      end

      it 'returns 0.75' do
        expect(assign).to eq(0.75)
      end

      it 'has a deficit of 0' do
        assign
        expect(part.deficit).to eq(0)
      end
    end
  end

  context 'with a deficit of 10' do
    before do
      5.times { |i| part.set_load(i, 1.0) }
    end

    context 'with hour 10' do
      it 'has 1 available' do
        expect(part.available_at(10)).to eq(1)
      end

      it 'has no mandatory input' do
        expect(part.mandatory_input_at(10)).to eq(0)
      end
    end

    context 'with hour 8750' do
      it 'has 1 available' do
        expect(part.available_at(8750)).to eq(1)
      end

      it 'has no mandatory input' do
        expect(part.mandatory_input_at(10)).to eq(0)
      end
    end

    context 'with hour 8755' do
      it 'has 0 available' do
        expect(part.available_at(8755)).to eq(0)
      end

      it 'has has 1 mandatory input' do
        expect(part.mandatory_input_at(8755)).to eq(1)
      end
    end

    context 'with hour 8758' do
      it 'has has 4 mandatory input' do
        expect(part.mandatory_input_at(8758)).to eq(4)
      end
    end


    context 'with hour 8759' do
      it 'has 0 available' do
        expect(part.available_at(8759)).to eq(0)
      end

      it 'has has 5 mandatory input' do
        expect(part.mandatory_input_at(8759)).to eq(5)
      end
    end
  end
end
