module Merit
  module LoadCurvePresenter
    module_function

    def present(order)
      order.participants.sort_by(&:key).map do |participant|
        case participant
        when User
          user_to_row(participant)
        when Producer
          producer_to_row(participant)
        end
      end
    end

    # Public: Dumps attributes for csv export. It's used in +load_curve+ in
    # order.rb. The build up as as follows:
    #
    # key                      - the technology key
    # class                    - the class name of the technology
    # output_capacity_per_unit - which is nil for users
    # number_of_units          - which is nil for users
    # load_curve               - the load curve
    #
    # Returns an array
    def user_to_row(user)
      [ user.key,
        user.class,
        nil,
        nil
      ] + user.load_curve.to_a
    end

    # Public: Dumps attributes for csv export. It's used in +load_curve+ in
    # order.rb. The build up as as follows:
    #
    # key                      - the technology key
    # class                    - the class name of the technology
    # output_capacity_per_unit - the output capacity per unit for a producer
    # number_of_units          - the number of units for a producer
    # load_curve               - the load curve
    #
    # Returns an array
    def producer_to_row(producer)
      [ producer.key,
        producer.class,
        producer.output_capacity_per_unit,
        producer.number_of_units
      ] + producer.load_curve.to_a
    end
  end
end
