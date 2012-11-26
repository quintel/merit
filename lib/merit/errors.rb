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
    "Cannot calculate if Demand is not (yet known)"
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

  InvalidChunkSize = error_class do |size|
    "You supplied an invalid chunk size of #{ size.inspect }; please " \
    "supply an integer greater than one. If you want to use a chunk size " \
    "of 1, use the Calculator class instead."
  end

end # Merit
