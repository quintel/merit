# frozen_string_literal: true

FactoryBot.define do
  factory :flex, class: Merit::Flex::Base do
    initialize_with { Merit::Flex::Base.new(attributes) }

    sequence(:key) { |n| :"flex_#{n}" }

    group { :a }
    input_capacity_per_unit { 2.0 }
    number_of_units { 1 }
    output_capacity_per_unit { 2.0 }

    factory :storage, class: Merit::Flex::Storage do
      initialize_with { Merit::Flex::Storage.new(attributes) }

      sequence(:key) { |n| :"storage_#{n}" }

      volume_per_unit { 0.05 }
    end
  end
end
