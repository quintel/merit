# frozen_string_literal: true

FactoryBot.define do
  factory :user, class: 'Merit::User' do
    initialize_with { Merit::User.create(attributes) }

    sequence(:key) { |n| :"user_#{n}" }

    factory :user_with_curve do
      load_curve { Merit::Curve.new([10.0] * 8760) }
    end

    factory :optimizing_storage_consumer do
      initialize_with { Merit::Flex::OptimizingStorage::Consumer.new(attributes) }
      load_curve { Merit::Curve.new([10.0] * 8760) }
    end
  end
end
