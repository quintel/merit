module Merit
  # Error class which serves as a base for all errors which occur in Merit.
  MeritError = Class.new(StandardError)

  # Internal: Creates a new error class which inherits from MeritError,
  # whose message is created by evaluating the block you give.
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
      def initialize(*args) ; super(make_message(*args)) ; end
      define_method(:make_message, &block)
    end
  end

  # Added a node to a graph, when one already exists with the same key.
  UnknownDemandError = error_class do
    "Cannot create a User without either :total_consumption or :load_curve"
  end

  MissingLoadProfileError = error_class do |key|
    "#{key} is not known. Please add."
  end

  IncorrectLoadProfileError = error_class do |key, size|
    "#{key} is malformatted. It needs to contain 8760 / n points." +
    "It now has #{size} points."
  end

  MissingAttributeError = error_class do |attribute, class_name|
    "Missing attribute #{attribute} for this instance of class #{class_name}."
  end

  LockedOrderError = error_class do |participant|
    "Cannot add #{ participant.key } participant since the order has " \
    "already been calcualted."
  end

  IncorrectProducerOrder = error_class do
    'Producers may not include any always-on producers after the first ' \
    'producer which is not always-on.'
  end

  InvalidChunkSize = error_class do |size|
    "You supplied an invalid chunk size of #{ size.inspect }; please " \
    "supply an integer greater than one. If you want to use a chunk size " \
    "of 1, use the Calculator class instead."
  end

  DuplicateParticipant = error_class do |name|
    "You added a participant called #{ name.inspect }; but that participant " \
    "had already been added"
  end

  SubZeroDemand = error_class do |point, demand|
    "Merit order has a subzero demand (#{ demand.inspect }) in point #{ point }"
  end

  MissingPriceCurve = error_class do |name|
    "You need to supply #{ name.inspect } with a :price_curve"
  end

  VariableMarginalCost = error_class do |obj|
    class_only = obj.class.name.split('::').last

    "#{ obj.class.name } has a variable marginal cost. Call " \
    "#{ class_only }#marginal_cost_at(point) to find the cost for a " \
    "particular point in time, or #{ class_only }#variable_costs to find " \
    "the total (annual) marginal cost applied to the load curve."
  end

end # Merit
