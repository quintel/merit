module Merit
  class User
    # A participant in the Merit Order which consumes energy. The amount of
    # energy consumed is expressed as a total amount per-year, and then mapped
    # to a load curve using a load profile.
    class TotalConsumption < User
      private

      # Internal: Creates a new TotalConsumption user. Please use User.create
      # instead of calling initialize directly.
      def initialize(options)
        super
        require_attributes :load_profile

        @total_consumption = options[:total_consumption]

        @load_curve = Curve.new(load_profile.values.map do |value|
          value * @total_consumption
        end)
      end
    end # TotalConsumption
  end # User
end # Merit
