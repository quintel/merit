module Merit
  class User
    # A participant in the Merit Order which consumes energy. The amount of
    # energy consumed is expressed as a total amount per-year, and then mapped
    # to a load curve using a load profile.
    class TotalConsumption < User
      # Public: the load curve of a participant, tells us how much energy
      # is produced at what time. It is a product of the load_profile and
      # the total_production.
      # Returns the load in MW
      def load_curve
        @load_curve ||= Curve.new(load_profile.values.map do |value|
          value * @total_consumption
        end)
      end

      #######
      private
      #######

      # Internal: Creates a new TotalConsumption user. Please use User.create
      # instead of calling initialize directly.
      def initialize(options)
        super
        require_attributes :load_profile

        @total_consumption = options[:total_consumption]
      end
    end # TotalConsumption
  end # User
end # Merit
