# frozen_string_literal: true

# rubocop:disable-next-line Style/Documentation
module Merit
  # Error class which serves as a base for all errors which occur in Merit.
  MeritError = Class.new(StandardError)

  # Internal: Creates a new error class which inherits from MeritError, whose message is created by
  # evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   raise MyError.new(5000, 2500)
  #   # => #<Merit::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = MeritError, &block)
    Class.new(superclass) do
      def initialize(*args)
        super(make_message(*args))
      end

      define_method(:make_message, &block)
    end
  end

  # Added a node to a graph, when one already exists with the same key.
  UnknownDemandError = error_class do
    'Cannot create a User without :total_consumption, :load_curve, or :consumption_share'
  end

  MissingFileError = error_class do |key|
    "No curve file at #{key.inspect}"
  end

  IncorrectLoadProfileError = error_class do |size, key = nil|
    "#{key || 'Load profile'} is malformatted. It needs to contain 8760 / n points. It now " \
      "has #{size} points."
  end

  MissingAttributeError = error_class do |attribute, class_name|
    "Missing attribute #{attribute} for this instance of class #{class_name}."
  end

  LockedOrderError = error_class do |participant|
    "Cannot add #{participant.key} participant since the order has already been calculated."
  end

  InvalidChunkSize = error_class do |size|
    "You supplied an invalid chunk size of #{size.inspect}; please supply an integer greater " \
      'than one. If you want to use a chunk size of 1, use the Calculator class instead.'
  end

  OutOfBounds = error_class do |point|
    "Cannot use out-of-bounds point #{point}"
  end

  InvalidCalculationOrder = error_class do |actual, expected|
    "Cannot calculate point #{actual} before #{expected}"
  end

  DuplicateParticipant = error_class do |name|
    "You added a participant called #{name.inspect}; but that participant had already been added."
  end

  NoCostData = error_class do |producer|
    "Couldn't determine how to calculate the cost for #{producer}. Did you forget to provide a " \
      ':marginal_costs attribute?'
  end

  SubZeroDemand = error_class do |point, demand|
    "Merit order has a subzero demand (#{demand.inspect}) in point #{point}"
  end

  MissingPriceCurve = error_class do |name|
    "You need to supply #{name.inspect} with a :price_curve"
  end

  InsufficentCapacityForPrice = error_class do |producer, point|
    "Cannot calculate a price for #{producer.key} in point ##{point} since there is insufficient " \
      'spare capacity for it to be price-setting.'
  end

  VariableMarginalCost = error_class do |obj|
    class_only = obj.class.name.split('::').last

    "#{obj.class.name} has a variable marginal cost. Call #{class_only}#marginal_cost_at(point) " \
      "to find the cost for a particular point in time, or #{class_only}#variable_costs to find " \
      'the total (annual) marginal cost applied to the load curve.'
  end

  IllegalPriceSensitiveUser = error_class do |inner|
    "#{inner.class.name} (#{inner.key}) cannot be made price-sensitive"
  end

  SortBlockRequired = error_class do |class_name|
    "Cannot use #{class_name} sorting without providing a block"
  end
end
