# frozen_string_literal: true

FactoryBot.define do
  factory :producer, class: 'Merit::Producer' do
    availability { 1.0 }
    fixed_costs_per_unit { 1.0 }
    fixed_om_costs_per_unit { 1.0 }
    full_load_hours { 8760 }
    marginal_costs { 10.0 }
    number_of_units { 1.0 }
    output_capacity_per_unit { 10.0 }

    factory :always_on, class: 'Merit::MustRunProducer' do
      initialize_with { Merit::MustRunProducer.new(attributes) }

      sequence(:key) { |n| :"always_on_#{n}" }

      load_profile { Merit::Curve.new([1.0 / 8760 / 3600] * Merit::POINTS) }
    end

    factory :curve_producer, class: 'Merit::MustRunProducer' do
      initialize_with { Merit::CurveProducer.new(attributes) }

      sequence(:key) { |n| :"curve_producer_#{n}" }

      load_curve { Merit::Curve.new([10.0] * Merit::POINTS) }
    end

    factory :dispatchable, class: 'Merit::DispatchableProducer' do
      initialize_with { Merit::DispatchableProducer.new(attributes) }

      sequence(:key) { |n| :"dispatchable_#{n}" }
    end
  end
end
