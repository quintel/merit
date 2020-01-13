# frozen_string_literal: true

require 'spec_helper'

describe Merit::CurveProducer do
  let(:load_curve) { Merit::Curve.new([1.0, 2.0]) }
  let(:producer) { described_class.new(options) }

  let(:options) do
    { key: :curve_producer, marginal_costs: 1.0, load_curve: load_curve }
  end

  context 'when initialized' do
    it 'must have a load_curve attribute' do
      options.delete(:load_curve)

      expect { described_class.new(options) }
        .to raise_error(Merit::MissingAttributeError, /load_curve/)
    end

    it 'must have a marginal_costs attribute' do
      options.delete(:marginal_costs)

      expect { described_class.new(options) }
        .to raise_error(Merit::NoCostData)
    end

    it 'assigns the load curve' do
      expect(producer.load_curve).to eq(load_curve)
    end
  end

  it 'uses the load curve for max_load_at' do
    expect(producer.max_load_at(0)).to eq(load_curve[0])
  end

  it 'returns the load curve for max_load_curve' do
    expect(producer.max_load_curve).to eq(load_curve)
  end

  it 'is always on' do
    expect(producer).to be_always_on
  end
end
