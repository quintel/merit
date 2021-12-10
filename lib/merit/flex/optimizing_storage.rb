# frozen_string_literal: true

module Merit
  module Flex
    module OptimizingStorage
      # Contains behavior for the production half of the optimizing storage.
      #
      # Production is determined by a curve. Unlike other always-on producers, optimizing storage
      # has a price and can be used to set the hourly price in Merit::PriceCurve.
      class Producer < Merit::CurveProducer
        def provides_price?
          true
        end
      end

      # Contains behavior for the consumption half of the optimizing storage.
      #
      # Consumption is determined by a curve. Unlike other users, optimizing storage has a price and
      # can be used to set the hourly price in Merit::PriceCurve.
      class Consumer < Merit::User::WithCurve
        public_class_method :new

        def provides_price?
          true
        end
      end
    end
  end
end
