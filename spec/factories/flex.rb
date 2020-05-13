# frozen_string_literal: true

FactoryBot.define do
  factory :flex, class: Merit::Flex::Base do
    initialize_with { Merit::Flex::Base.new(attributes) }

    sequence(:key) { |n| :"flex_#{n}" }

    output_capacity_per_unit { 2.0 }
    number_of_units { 1 }
    group { :a }
    input_capacity_per_unit { 2.0 }
  end
end
