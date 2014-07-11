module Merit
  class User
    class WithCurve < User
      # Public: The load curve representing the hourly demand of the User.
      attr_reader :load_curve

      #######
      private
      #######

      def initialize(options)
        super
        @load_curve = options[:load_curve]
      end
    end # WithCurve
  end # User
end # Merit
