# frozen_string_literal: true

module Merit
  class User
    # A user whose demand is determined with a Curve.
    class WithCurve < User
      # Public: The load curve representing the hourly demand of the User.
      attr_reader :load_curve

      private

      def initialize(options)
        super
        @load_curve = options[:load_curve]
      end
    end
  end
end
